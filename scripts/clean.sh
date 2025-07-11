#!/bin/bash

source "$(dirname "$0")/../config.sh"

echo -e "${GREEN}Cleaning the project...${NC}"

# Handle initramfs directory cleanup
if [ -d "$INITRAMFS_DIR" ]; then
    if [ "$(ls -A "$INITRAMFS_DIR" 2>/dev/null)" ]; then
        echo -e "${BLUE}Removing initramfs files...${NC}"
        rm -rf "$INITRAMFS_DIR"/*
        echo -e "${GREEN}Removing initramfs files completed successfully!${NC}"
    else
        echo -e "${YELLOW}Initramfs directory exists but is empty. Nothing to clean.${NC}"
    fi
else
    echo -e "${RED}Initramfs directory doesn't exist. Skipping...${NC}"
fi

# Handle build directory cleanup
if [ -d "$BUILD_DIR" ]; then
    if [ "$(ls -A "$BUILD_DIR" 2>/dev/null)" ]; then
        echo -e "${BLUE}Removing build files...${NC}"
        rm -rf "$BUILD_DIR"/*
        echo -e "${GREEN}Removing build files completed successfully!${NC}"
    else
        echo -e "${YELLOW}Build directory exists but is empty. Nothing to clean.${NC}"
    fi
else
    echo -e "${RED}Build directory doesn't exist. Skipping...${NC}"
fi

# Handle temp directory cleanup
if [ -d "$TEMP_DIR" ]; then
    if [ "$(ls -A "$TEMP_DIR" 2>/dev/null)" ]; then
        echo -e "${BLUE}Removing temporary files...${NC}"
        rm -rf "$TEMP_DIR"/*
        echo -e "${GREEN}Removing temporary files completed successfully!${NC}"
    else
        echo -e "${YELLOW}Temp directory exists but is empty. Nothing to clean.${NC}"
    fi
else
    echo -e "${RED}Temp directory doesn't exist. Skipping...${NC}"
fi

# Handle sources directory cleanup
#if [ -d "$SOURCES_DIR" ]; then
    #if [ "$(ls -A "$SOURCES_DIR" 2>/dev/null)" ]; then
        #echo -e "${BLUE}Cleaning sources directory...${NC}"
        #rm -rf "$SOURCES_DIR"/*
        #echo -e "${GREEN}Cleaning sources directory completed successfully!${NC}"
    #else
        #echo -e "${YELLOW}Sources directory exists but is empty. Nothing to clean.${NC}"
    #fi
#else
    #echo -e "${RED}Temp directory doesn't exist. Skipping...${NC}"
#fi

echo -e "${DARK_GREEN}Done.${NC}"