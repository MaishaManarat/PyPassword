 #Password Generator Project


    
logo = r"""


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

"""
 
print (logo)

import random
lowercase_letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
uppercase_letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
symbols = ['!', '#', '$', '%', '&', '(', ')', '*', '+', '{', '}', '<', '>', '[',']', '@', '^']

print("\033[32m     Welcome to the PyPassword Generator! \033[0m")
print("\n\033[90mpassword length must be greater than 9\033[0m")
print("\033[90mpassword will include uppercase letters, lowercase letters, numbers and symbols\n\033[0m")
length = int(input("\033[33mEnter Password Length:  \033[0m"))

  

def randomness_of_characters():
    # Pick 2 unique split points between 0 and length
    # splits = sorted(random.sample(range(2, length), 2))
    splits = random.sample(range(4,length-4), 2)
    
    x = splits[0]
    y = length - splits[0]
    
    splits_x = random.sample(range(1,x-1), 2)
    splits_y = random.sample(range(1,y-1), 2)
   
    # Calculate the three segments
    ll = splits_x[0]
    ul = x - splits_x[0]
    nr = splits_y[0]
    sy = y - splits_y[0]
    
    sumof = ll+ul+nr+sy
    
    return ll,ul,nr,sy,sumof

#lol = randomness_of_characters()

#print (lol)


def pass_gen():
  lol = randomness_of_characters()
  random_ll = ""
  for a in range (lol[0]):
    a = random.choice(lowercase_letters)
    random_ll = a + random_ll
  #print(random_ll)

  random_ul = ""
  for b in range (lol[1]):
    b = random.choice(uppercase_letters)
    random_ul = b + random_ul
  #print(random_ul)

  random_sy = ""
  for c in range (lol[2]):
    c = random.choice(symbols)
    random_sy = c + random_sy
  #print(random_sy)

  random_nr = ""
  for d in range (lol[3]):
    d = random.choice(numbers)
    random_nr = d + random_nr
  #print(random_nr)


  r = random_ll + random_ul + random_sy +random_nr
  password_list = list(r)
  random.shuffle(password_list)

  password = ""
  for i in password_list:
    password = i + password

  return password

#password = pass_gen()

def main():
  password = pass_gen()
  print(f"\n\033[37mGenerated Password:\033[0m \033[92m{password}\033[0m")

if (length<=9):
  print("\n\033[31mError!! Please select length number greater 9\033[0m")
else:
  main()
  
