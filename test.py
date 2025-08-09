def count_letters(text):
    letter_count = {}
    for char in text:
        if char.isalpha():
            char = char.lower()
            letter_count[char] = letter_count.get(char, 0) + 1
    return letter_count

if __name__ == "__main__":
    sample_text = "Hello, World!"
    print(count_letters(sample_text))
    