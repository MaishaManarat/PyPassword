# Password Generator Project - GUI Edition (Windows Forms)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$logo = @"
    /                        \
  /X/                        \X\
|XX\         _____         /XX|
|XXX\      /       \_     /XXX|___________
 \XXXXXXX              XXXXXXX/            \
    \XXXX    /     \    XXXXX/              \
        |   0     0   |                     \
         |         |                       \
          \       /                         |______//
           \     /                          |
            | O_O | \                         |
             \ _ /   \________________          |
                    | |  | |      \        /
  No Bullshit,      / |  / |       \______/
    Please...        \ |  \ |        \ |  \ |
                    __| |__| |      __| |__| |
                    |___||___|      |___||___|
"@

$lowercase_letters = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
$uppercase_letters = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
$numbers = '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
$symbols = '!', '#', '$', '%', '&', '(', ')', '*', '+', '{', '}', '<', '>', '[', ']', '@', '^'

# ---- Core generation logic (ported from the console version) ----

function Get-RandomSplits {
    param([int]$Length)

    $range = 4..($Length - 4)
    $splits = $range | Get-Random -Count 2 | Sort-Object

    $x = $splits[0]
    $y = $Length - $splits[0]

    $splits_x = (1..($x - 1)) | Get-Random -Count 2
    $splits_y = (1..($y - 1)) | Get-Random -Count 2

    $ll = $splits_x[0]
    $ul = $x - $splits_x[0]
    $nr = $splits_y[0]
    $sy = $y - $splits_y[0]

    return ,@($ll, $ul, $nr, $sy)
}

function Get-GeneratedPassword {
    param([int]$Length)

    $parts = Get-RandomSplits -Length $Length

    $random_ll = ""
    for ($a = 0; $a -lt $parts[0]; $a++) {
        $random_ll = ($lowercase_letters | Get-Random) + $random_ll
    }

    $random_ul = ""
    for ($b = 0; $b -lt $parts[1]; $b++) {
        $random_ul = ($uppercase_letters | Get-Random) + $random_ul
    }

    # NOTE: the original console script indexed $lol[1] for both the symbol
    # and number loops (a copy-paste bug), which meant numbers were never
    # actually added and the symbol count was wrong. Fixed here to use
    # $parts[2] (numbers) and $parts[3] (symbols) as intended.
    $random_nr = ""
    for ($c = 0; $c -lt $parts[2]; $c++) {
        $random_nr = ($numbers | Get-Random) + $random_nr
    }

    $random_sy = ""
    for ($d = 0; $d -lt $parts[3]; $d++) {
        $random_sy = ($symbols | Get-Random) + $random_sy
    }

    $r = $random_ll + $random_ul + $random_sy + $random_nr
    $password_list = $r.ToCharArray()
    $shuffled_list = $password_list | Get-Random -Count $password_list.Length

    return -join $shuffled_list
}

# ---- Theme ----
# Muted, low-saturation grayscale palette with a single soft-green accent
# reserved for the generated password itself.

$colorBg          = [System.Drawing.Color]::FromArgb(24, 24, 26)   # window background
$colorPanel       = [System.Drawing.Color]::FromArgb(32, 32, 35)   # logo panel background
$colorFieldBg     = [System.Drawing.Color]::FromArgb(42, 42, 46)   # input field background
$colorFieldBorder = [System.Drawing.Color]::FromArgb(66, 66, 70)
$colorResultBg    = [System.Drawing.Color]::FromArgb(18, 18, 20)
$colorTextPrimary = [System.Drawing.Color]::FromArgb(230, 230, 230)
$colorTextMuted   = [System.Drawing.Color]::FromArgb(148, 148, 150)
$colorAccentGreen = [System.Drawing.Color]::FromArgb(122, 168, 116)  # sage/muted green (logo + password text)
$colorButtonMain  = [System.Drawing.Color]::FromArgb(58, 74, 58)     # dark desaturated green
$colorButtonMainH = [System.Drawing.Color]::FromArgb(72, 92, 72)     # hover state
$colorButtonGray  = [System.Drawing.Color]::FromArgb(50, 50, 54)     # grayscale secondary button
$colorButtonGrayH = [System.Drawing.Color]::FromArgb(64, 64, 68)
$colorSuccess     = [System.Drawing.Color]::FromArgb(122, 168, 116)
$colorError       = [System.Drawing.Color]::FromArgb(196, 106, 106)

# ---- GUI ----

$form = New-Object System.Windows.Forms.Form
$form.Text = "PyPassword Generator"
$form.Size = New-Object System.Drawing.Size(560, 620)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $colorBg

# Logo
$logoBox = New-Object System.Windows.Forms.TextBox
$logoBox.Multiline = $true
$logoBox.ReadOnly = $true
$logoBox.BorderStyle = "None"
$logoBox.Font = New-Object System.Drawing.Font("Consolas", 7)
$logoBox.BackColor = $colorPanel
$logoBox.ForeColor = $colorAccentGreen
$logoBox.Text = $logo
$logoBox.Location = New-Object System.Drawing.Point(10, 10)
$logoBox.Size = New-Object System.Drawing.Size(530, 260)
$logoBox.TabStop = $false
$form.Controls.Add($logoBox)

# Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Welcome to the PyPassword Generator!"
$titleLabel.ForeColor = $colorTextPrimary
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(10, 275)
$form.Controls.Add($titleLabel)

# Subtitle
$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Length must be greater than 9. Includes uppercase, lowercase, numbers and symbols."
$subLabel.ForeColor = $colorTextMuted
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subLabel.AutoSize = $true
$subLabel.Location = New-Object System.Drawing.Point(10, 305)
$subLabel.MaximumSize = New-Object System.Drawing.Size(530, 0)
$form.Controls.Add($subLabel)

# Length label + input
$lengthLabel = New-Object System.Windows.Forms.Label
$lengthLabel.Text = "Password Length:"
$lengthLabel.ForeColor = $colorTextPrimary
$lengthLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lengthLabel.AutoSize = $true
$lengthLabel.Location = New-Object System.Drawing.Point(10, 345)
$form.Controls.Add($lengthLabel)

$lengthInput = New-Object System.Windows.Forms.NumericUpDown
$lengthInput.Minimum = 10
$lengthInput.Maximum = 128
$lengthInput.Value = 12
$lengthInput.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lengthInput.BackColor = $colorFieldBg
$lengthInput.ForeColor = $colorTextPrimary
$lengthInput.BorderStyle = "FixedSingle"
$lengthInput.Location = New-Object System.Drawing.Point(160, 342)
$lengthInput.Size = New-Object System.Drawing.Size(70, 25)
$form.Controls.Add($lengthInput)

# Generate button
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = "Generate Password"
$generateButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$generateButton.BackColor = $colorButtonMain
$generateButton.ForeColor = $colorTextPrimary
$generateButton.FlatStyle = "Flat"
$generateButton.FlatAppearance.BorderSize = 0
$generateButton.FlatAppearance.MouseOverBackColor = $colorButtonMainH
$generateButton.FlatAppearance.MouseDownBackColor = $colorButtonMainH
$generateButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$generateButton.Location = New-Object System.Drawing.Point(260, 340)
$generateButton.Size = New-Object System.Drawing.Size(160, 30)
$form.Controls.Add($generateButton)

# Result box
$resultBox = New-Object System.Windows.Forms.TextBox
$resultBox.ReadOnly = $true
$resultBox.Font = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
$resultBox.ForeColor = $colorAccentGreen
$resultBox.BackColor = $colorResultBg
$resultBox.BorderStyle = "FixedSingle"
$resultBox.TextAlign = "Center"
$resultBox.Location = New-Object System.Drawing.Point(10, 390)
$resultBox.Size = New-Object System.Drawing.Size(530, 35)
$form.Controls.Add($resultBox)

# Copy button (grayscale, secondary action)
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy to Clipboard"
$copyButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$copyButton.BackColor = $colorButtonGray
$copyButton.ForeColor = $colorTextPrimary
$copyButton.FlatStyle = "Flat"
$copyButton.FlatAppearance.BorderSize = 0
$copyButton.FlatAppearance.MouseOverBackColor = $colorButtonGrayH
$copyButton.FlatAppearance.MouseDownBackColor = $colorButtonGrayH
$copyButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$copyButton.Location = New-Object System.Drawing.Point(10, 435)
$copyButton.Size = New-Object System.Drawing.Size(160, 28)
$form.Controls.Add($copyButton)

# Status label (for errors / confirmations)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = ""
$statusLabel.ForeColor = $colorTextMuted
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(180, 440)
$form.Controls.Add($statusLabel)

# ---- Event handlers ----

$generateButton.Add_Click({
    $length = [int]$lengthInput.Value
    if ($length -le 9) {
        $resultBox.Text = ""
        $statusLabel.ForeColor = $colorError
        $statusLabel.Text = "Error! Length must be greater than 9."
        return
    }
    try {
        $resultBox.Text = Get-GeneratedPassword -Length $length
        $statusLabel.ForeColor = $colorSuccess
        $statusLabel.Text = "Password generated."
    }
    catch {
        $statusLabel.ForeColor = $colorError
        $statusLabel.Text = "Something went wrong, try again."
    }
})

$copyButton.Add_Click({
    if ($resultBox.Text -ne "") {
        [System.Windows.Forms.Clipboard]::SetText($resultBox.Text)
        $statusLabel.ForeColor = $colorSuccess
        $statusLabel.Text = "Copied to clipboard!"
    }
})

[void]$form.ShowDialog()
