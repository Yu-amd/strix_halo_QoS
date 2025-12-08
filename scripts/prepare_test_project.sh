#!/bin/bash
# Prepare Test Project Script
# Clones and configures a CMake-based C++ project for the Developer demo

set -e

PROJECT_NAME="${1:-llvm-project}"
PROJECT_DIR="test-projects/$PROJECT_NAME"

echo "=== Preparing Test Project for Developer Demo ==="
echo ""

# Options for test projects
case "$PROJECT_NAME" in
    llvm-project)
        REPO_URL="https://github.com/llvm/llvm-project.git"
        SUBDIR="."
        USE_SPARSE=false
        echo "Using LLVM project (large, good for stress testing)"
        echo "Note: This will download ~500MB and take several minutes"
        ;;
    json)
        REPO_URL="https://github.com/nlohmann/json.git"
        SUBDIR="."
        USE_SPARSE=false
        echo "Using nlohmann/json (small, quick to build)"
        ;;
    spdlog)
        REPO_URL="https://github.com/gabime/spdlog.git"
        SUBDIR="."
        USE_SPARSE=false
        echo "Using spdlog (medium size)"
        ;;
    catch2)
        REPO_URL="https://github.com/catchorg/Catch2.git"
        SUBDIR="."
        USE_SPARSE=false
        echo "Using Catch2 (testing framework, medium size)"
        ;;
    *)
        echo "Unknown project: $PROJECT_NAME"
        echo "Available projects: json, spdlog, catch2, llvm-project"
        exit 1
        ;;
esac

# Create test-projects directory
mkdir -p test-projects

# Clone or update project
if [ -d "$PROJECT_DIR" ]; then
    echo "Project already exists at $PROJECT_DIR"
    read -p "Remove and re-clone? (y/N): " answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        rm -rf "$PROJECT_DIR"
    else
        echo "Using existing project"
        cd "$PROJECT_DIR"
        if [ -d ".git" ]; then
            echo "Updating project..."
            git pull
        fi
        cd - > /dev/null
    fi
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Cloning $PROJECT_NAME..."
    if [ "$USE_SPARSE" = true ] && [ "$SUBDIR" != "." ]; then
        # For large projects, do a shallow clone of just the subdirectory
        echo "Cloning (this may take a few minutes)..."
        git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$PROJECT_DIR"
        cd "$PROJECT_DIR"
        git sparse-checkout set "$SUBDIR"
        cd - > /dev/null
    else
        # Full clone (needed for LLVM and most projects)
        if [ "$PROJECT_NAME" = "llvm-project" ]; then
            echo "Cloning LLVM (this will take several minutes and download ~500MB)..."
            git clone --depth 1 "$REPO_URL" "$PROJECT_DIR"
        else
            git clone --depth 1 "$REPO_URL" "$PROJECT_DIR"
        fi
    fi
    echo "✓ Project cloned"
fi

# Check for CMakeLists.txt
if [ "$SUBDIR" != "." ]; then
    CMAKE_PATH="$PROJECT_DIR/$SUBDIR"
else
    CMAKE_PATH="$PROJECT_DIR"
fi

# For LLVM, we need to configure from the root but build in llvm
if [ "$PROJECT_NAME" = "llvm-project" ]; then
    # LLVM needs to be configured from the root with llvm as subdirectory
    CMAKE_PATH="$PROJECT_DIR"
    BUILD_SUBDIR="llvm"
else
    BUILD_SUBDIR="."
fi

# Check for CMakeLists.txt
if [ "$PROJECT_NAME" = "llvm-project" ]; then
    # LLVM has CMakeLists.txt in llvm subdirectory
    CMAKE_FILE="$CMAKE_PATH/llvm/CMakeLists.txt"
else
    CMAKE_FILE="$CMAKE_PATH/CMakeLists.txt"
fi

if [ ! -f "$CMAKE_FILE" ]; then
    echo "⚠ Warning: CMakeLists.txt not found at $CMAKE_FILE"
    echo "The project may not be CMake-based or the structure is different"
    exit 1
fi

echo "✓ CMakeLists.txt found"

# Configure build
echo ""
echo "Configuring CMake build (this may take a few minutes)..."
cd "$CMAKE_PATH"

# LLVM needs special configuration - build from root with llvm as source
if [ "$PROJECT_NAME" = "llvm-project" ]; then
    cmake -S llvm -B build -DCMAKE_BUILD_TYPE=Release \
          -DLLVM_ENABLE_PROJECTS="clang" \
          -DLLVM_TARGETS_TO_BUILD="X86" \
          -DCMAKE_BUILD_TYPE=MinSizeRel
    # Update CMAKE_PATH for demo script
    CMAKE_PATH="$CMAKE_PATH/llvm"
else
    cmake -B build -DCMAKE_BUILD_TYPE=Release
fi

echo ""
echo "✓ Test project prepared successfully!"
echo ""
echo "Project location: $CMAKE_PATH"
echo "Build directory: $CMAKE_PATH/build"
echo ""
echo "To use this project in the demo, run:"
if [ "$PROJECT_NAME" = "llvm-project" ]; then
    echo "  ./scripts/dev_qos_demo.sh --project-path $CMAKE_PATH"
    echo ""
    echo "Note: LLVM builds can take 30+ minutes. For quicker testing, use:"
    echo "  ./scripts/prepare_test_project.sh json"
else
    echo "  ./scripts/dev_qos_demo.sh --project-path $CMAKE_PATH"
fi

