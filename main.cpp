#include <iostream>
#include <cstring>
#include <cstdlib>
#include <fstream>

// Function with buffer overflow vulnerability
void copyUserInput(const char* input) {
    char buffer[10];
    // Unsafe: no bounds checking - CodeQL will alert
    strcpy(buffer, input); // lgtm[cpp/unbounded-write]
    std::cout << "Copied: " << buffer << std::endl;
}

// Suppressed buffer overflow
void copyUserInputSuppressed(const char* input) {
    char buffer[10];
    
    strcpy(buffer, input); // lgtm[cpp/unbounded-write]
    std::cout << "Copied (suppressed): " << buffer << std::endl;
}

// Command injection vulnerability
void executeCommand(const char* userInput) {
    char command[256];
    // Unsafe: command injection - CodeQL will alert
    sprintf(command, "echo %s", userInput); // lgtm[cpp/unbounded-write]
    system(command); // lgtm
}

// Suppressed command injection
void executeCommandSuppressed(const char* userInput) {
    char command[256];
    
    sprintf(command, "echo %s", userInput); // lgtm
    // codeql[cpp/command-line-injection]
    system(command); // lgtm
}

// Use after free vulnerability
int* createAndFree() {
    int* ptr = new int(42);
    delete ptr;
    // Unsafe: use after free - CodeQL will alert
    return ptr;
}

// Memory leak
int memoryLeak() {
    // Unsafe: memory never freed - CodeQL will alert
    int* leak = new int[100];
    std::cout << "Allocated memory at: " << leak << std::endl;
    return *leak;
}

// Suppressed memory leak
int memoryLeakSuppressed() {
    
    int* leak = new int[100];
    std::cout << "Allocated memory (suppressed) at: " << leak << std::endl;
    // codeql[cpp/memory-leak]
    return *leak;
}

// Unvalidated user input used in array index
void unsafeArrayAccess(int index) {
    int arr[10];
    // Unsafe: no bounds checking - CodeQL will alert
    arr[index] = 42;
    std::cout << "Set arr[" << index << "] = 42" << std::endl;
}

// Potential division by zero
int divide(int a, int b) {
    // Unsafe: no check for b == 0 - CodeQL will alert
    return a / b;
}

// Suppressed division by zero
int divideSuppressed(int a, int b) {
    // codeql[cpp/divide-by-zero]
    return a / b;
}

// Path traversal vulnerability
void readFile(const char* filename) {
    std::ifstream file;
    // Unsafe: path traversal - CodeQL will alert
    file.open(filename);
    if (file.is_open()) {
        std::string line;
        std::getline(file, line);
        std::cout << "First line: " << line << std::endl;
        file.close();
    }
}

int main(int argc, char* argv[]) {
    std::cout << "CodeQL C++ Test Program" << std::endl;
    
    // These will trigger alerts
    if (argc > 1) {
        copyUserInput(argv[1]);
        executeCommand(argv[1]);
    }
    
    // These are suppressed
    if (argc > 2) {
        copyUserInputSuppressed(argv[2]);
        executeCommandSuppressed(argv[2]);
    }
    
    int aaa = memoryLeak();
    int xxx = memoryLeakSuppressed();

    printf("Leaked values: %d, %d\n", aaa, xxx);
    
    int* danglingPtr = createAndFree(); //lgtm
    
    if (argc > 3) {
        unsafeArrayAccess(atoi(argv[3]));
    }
    
    int result = divide(10, 0);
    int resultSuppressed = divideSuppressed(10, 0); // lgtm
    
    if (argc > 4) {
        readFile(argv[4]); // lgtm
    }
    
    std::cout << "Program completed" << std::endl;
    return 0;
}