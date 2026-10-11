namespace DrpgServer;

public static class Log
{
    private static readonly object Gate = new();

    // The debug loop reads server.log, so mirror everything to it (console alone is lost when the
    // server is launched detached, e.g. tools/play.ps1). Truncated once per process on first write.
    private static readonly string FilePath = Path.Combine(Directory.GetCurrentDirectory(), "server.log");
    private static bool _fileReset;

    public static void Info(string msg) => Write(ConsoleColor.Gray, msg);
    public static void Warn(string msg) => Write(ConsoleColor.Yellow, msg);
    public static void Error(string msg) => Write(ConsoleColor.Red, msg);

    public static void Http(string method, string path, int status) =>
        Write(status >= 400 ? ConsoleColor.DarkYellow : ConsoleColor.DarkGray, $"{method} {path} -> {status}");

    private static void Write(ConsoleColor color, string msg)
    {
        lock (Gate)
        {
            var line = $"[{DateTime.Now:HH:mm:ss}] {msg}";
            Console.ForegroundColor = color;
            Console.WriteLine(line);
            Console.ResetColor();
            try
            {
                if (!_fileReset) { File.WriteAllText(FilePath, ""); _fileReset = true; }
                File.AppendAllText(FilePath, line + Environment.NewLine);
            }
            catch { /* never let logging crash the request */ }
        }
    }
}
