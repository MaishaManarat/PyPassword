 #Password Generator Project

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
 
Write-Host $logo

$lowercase_letters = 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
$uppercase_letters = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
$numbers = '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
$symbols = '!', '#', '$', '%', '&', '(', ')', '*', '+', '{', '}', '<', '>', '[',']', '@', '^'

Write-Host "           Welcome to the PyPassword Generator!" -ForegroundColor Green
Write-Host "password length must be greater than 9" -ForegroundColor Cyan
Write-Host "password will include uppercase letters, lowercase letters, numbers and symbols" -ForegroundColor Cyan

$lengthStr = Read-Host "Enter Password Length: " 
$length = [int]$lengthStr

  
function randomness_of_characters {
  $range = 4..($length - 4)
  $splits = $range | Get-Random -Count 2 | Sort-Object

  $x = $splits[0]
  $y = $length - $splits[0]
    
  $splits_x = (1..($x - 1)) | Get-Random -Count 2
  $splits_y = (1..($y - 1)) | Get-Random -Count 2
    
  $ll = $splits_x[0]
  $ul = $x - $splits_x[0]
  $nr = $splits_y[0]
  $sy = $y - $splits_y[0]
    
  $sumof = $ll + $ul + $nr + $sy
    
  return ,@($ll, $ul, $nr, $sy, $sumof)
}


function get_pass{
  $lol = randomness_of_characters 

  $random_ll = ""
    for ($a = 0; $a -lt $lol[0]; $a++) {
        $char = $lowercase_letters | Get-Random
        $random_ll = $char + $random_ll
    }

  $random_ul = ""
    for ($b = 0; $b -lt $lol[1]; $b++) {
        $char = $uppercase_letters | Get-Random
        $random_ul = $char + $random_ul
    }


  $random_sy = ""
    for ($c = 0; $c -lt $lol[1]; $c++) {
        $char = $symbols | Get-Random
        $random_sy = $char + $random_sy
    }


  $random_nr = ""
    for ($d = 0; $d -lt $lol[1]; $d++) {
        $char = $numbers | Get-Random
        $random_nr = $char + $random_nr
    }

  $r = $random_ll + $random_ul + $random_sy + $random_nr
  $password_list = $r.ToCharArray()
  $shuffled_list = $password_list | Get-Random -Count $password_list.Length

  $password = -join $shuffled_list
  return $password

}

function Invoke-Main {
    $password = get_pass
    Write-Host "`Generated Password: $password"  -ForegroundColor Green
}

if ($length -le 9) {
    Write-Host "Error!! Please select length number greater"  -ForegroundColor Red
} else {
    Invoke-Main
}

Read-Host -Prompt "Press Enter to exit..."
