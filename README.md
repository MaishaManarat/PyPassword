# 🔐 PyPassword Generator

> **Comment:** Reproduced old project during my python learning journey to workable day to day use. Basically i got tired of thinking new pass during every BAU activity


A simple command-line password generator built in Python. It creates strong, randomized passwords made up of a shuffled mix of lowercase letters, uppercase letters, numbers, and symbols — no external dependencies required.

```
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
```

## ✨ Features

- Generates passwords containing a random mix of:
  - Lowercase letters (a–z)
  - Uppercase letters (A–Z)
  - Numbers (0–9)
  - Symbols (`!#$%&()*+{}<>[]@^`)
- Randomly splits the requested length across each character type, so the composition changes every run
- Shuffles the final character order for extra unpredictability
- Colorized terminal output for a friendlier CLI experience
- Minimum length enforcement (must be greater than 9) to encourage stronger passwords

## 📋 Requirements

- Python 3.x
- No external packages — uses only the built-in `random` module

## 🚀 Installation

1. Clone this repository:
   ```
   git clone https://github.com/your-username/pypassword-generator.git
   cd pypassword-generator
   ```
2. Run the script directly — no `pip install` needed.


## 🖥️ Usage

Run the script from your terminal:

```
python password_generator.py
```

I have added an exe version, which i let deepseek create gui for. If do no not trust exe, make your own by

   ```
   pip install pyinstaller
   pyinstaller --onedir password_generator.py
   ```

You'll be prompted to enter a desired password length (must be greater than 9):

```
Welcome to the PyPassword Generator!

password length must be greater than 9
password will include uppercase letters, lowercase letters, numbers and symbols

Enter Password Length:  16

Generated Password: 
```

Press **Enter** to exit once your password is generated.

## ⚙️ How It Works

1. The script asks for a target password length.
2. `randomness_of_characters()` randomly splits that length into four segments — one each for lowercase letters, uppercase letters, numbers, and symbols — so the ratio of character types differs on every run.
3. `pass_gen()` builds a random string for each segment, combines them, and shuffles the combined characters.
4. The final shuffled string is returned and printed as the generated password.



## 🤝 Contributing

Contributions, bug reports, and suggestions are welcome! Feel free to open an issue or submit a pull request.

## 📄 License

This project is available under the [MIT License](LICENSE).
