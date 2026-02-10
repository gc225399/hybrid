<# ::
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0') -join [Environment]::Newline); iex 'main %*'"
goto :eof
#>

function main {
	$code = @'
	using System;
	using System.Runtime.InteropServices;
	using System.Drawing;
	using System.Windows.Forms;

	public class Meltdown {
		[DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr h);
		[DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr d, int x, int y, int w, int h, IntPtr s, int sx, int sy, uint r);
		[DllImport("user32.dll")] public static extern int GetSystemMetrics(int i);
		[DllImport("user32.dll")] public static extern bool DrawIcon(IntPtr h, int x, int y, IntPtr i);
		[DllImport("user32.dll")] public static extern IntPtr LoadIcon(IntPtr h, IntPtr i);
		[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
		[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
		[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
		[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
		[DllImport("user32.dll")] public static extern void keybd_event(byte b, byte s, uint f, int d);
		[DllImport("user32.dll")] public static extern bool InvalidateRect(IntPtr h, IntPtr r, bool b);

		public static void Start() {
			IntPtr hWnd = GetForegroundWindow();
			ShowWindow(hWnd, 0); // Hide Console
			SetProcessDPIAware();

			IntPtr hdc = GetDC(IntPtr.Zero);
			int w = GetSystemMetrics(78); 
			int h = GetSystemMetrics(79); 
			IntPtr errorIcon = LoadIcon(IntPtr.Zero, (IntPtr)32513);
			Random rand = new Random();

			while (true) {
				// EXIT HOTKEY: CTRL + `
				if ((GetAsyncKeyState(0x11) & 0x8000) != 0 && (GetAsyncKeyState(0xC0) & 0x8000) != 0) break;

				// 1. TUNNELING (Sucks the screen inward)
				if (rand.Next(0, 15) == 1) 
					BitBlt(hdc, 10, 10, w - 20, h - 20, hdc, 0, 0, 0x00CC0020);

				// 2. KEYBOARD DISCO (Caps Lock Flash)
				if (rand.Next(0, 30) == 1) {
					keybd_event(0x14, 0x45, 0, 0); 
					keybd_event(0x14, 0x45, 2, 0);
				}

				// 3. THE SHAKE & MELT
				int x = rand.Next(-15, 15);
				int y = rand.Next(-15, 15);
				BitBlt(hdc, x, y, w, h, hdc, 0, 0, 0x00CC0020);

				// Mouse Following Icon
				Point m = Cursor.Position;
				DrawIcon(hdc, m.X, m.Y, errorIcon);

				// Rare Full Color Invert
				if (rand.Next(0, 50) == 1) 
					BitBlt(hdc, 0, 0, w, h, hdc, 0, 0, 0x00550009);

				System.Threading.Thread.Sleep(10);
			}

			// CLEAN UP: Forces Windows to redraw everything
			InvalidateRect(IntPtr.Zero, IntPtr.Zero, true);
		}
	}
'@

	Add-Type -TypeDefinition $code -ReferencedAssemblies @('System.Drawing','System.Windows.Forms')
	[Meltdown]::Start()
}