on run {input, parameters}

    -- Calculate total file size
    set totalSize to 0

    repeat with anItem in input
        set fileSize to (do shell script "du -sk " & quoted form of POSIX path of anItem & " | awk '{print $1}'")
        set totalSize to totalSize + fileSize as integer
    end repeat

    -- Get file list
    set fileList to ""
    
    repeat with anItem in input
        set itemPath to POSIX path of anItem
        set fileList to fileList & " " & quoted form of itemPath
    end repeat
    
    -- Add additional space to the total size
    -- Calculate 1 percent of totalSize
    set additionalSize to totalSize * 0.01
    set totalSize to totalSize + additionalSize

    -- Prompt for password input
    set passwordPrompt to display dialog "What would you like the password to be?" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer

    if button returned of passwordPrompt is "OK" then
        set enteredPassword to text returned of passwordPrompt

        -- Prompt to verify the password
        set verifyPrompt to display dialog "Verify the password:" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer
        
        if button returned of verifyPrompt is "OK" then
            set verifiedPassword to text returned of verifyPrompt
            
            -- Check if passwords match
            if enteredPassword = verifiedPassword then
                set diskImagePassword to enteredPassword

                -- Set the path for the new disk image
                set diskImagePath to "/tmp/SchrödingerBox.dmg"
                
                -- Create a new disk image with the specified parameters
                do shell script "printf " & quoted form of diskImagePassword & "|hdiutil create -size " & totalSize & "k -fs APFS -encryption AES-256 -stdinpass -volname SchrödingerBox " & quoted form of diskImagePath
                
                set homeFolderPath to POSIX path of (path to home folder)
                set mountedImagePath to homeFolderPath & "SchrödingerBox.dmg"
                do shell script "mv " & quoted form of diskImagePath & " " & quoted form of mountedImagePath

                -- Mount the disk image
                set destinationPath to "/Volumes/SchrödingerBox/"
                do shell script "printf " & quoted form of diskImagePassword & " | hdiutil attach -stdinpass " & quoted form of mountedImagePath

                -- Wait until the disk image is mounted
                repeat
                    delay 1
                    set mountedVolumes to do shell script "ls /Volumes"
                    if mountedVolumes contains "SchrödingerBox" then
                        exit repeat
                    end if
                end repeat
                
                -- Decide whether or not to kill the cat
                set randomValue to (random number from 0 to 1)
                if randomValue is 1 then
                    -- Copy data to disk image
                    do shell script "rsync -avR  " & fileList & " " & quoted form of destinationPath
                else
                    -- Create a dummy file on the disk image named "The cat is dead."
                    set totalSize to 0
                    repeat with anItem in input
                        set itemPath to POSIX path of anItem
                        set fileSize to (do shell script "du -sk " & quoted form of itemPath & " | awk '{print $1}'")
                        set totalSize to totalSize + fileSize
                    end repeat
                    set dummyFilePath to destinationPath & "The cat is dead."
                    -- Create a dummy file with the total size filled with zero bytes
                    do shell script "dd if=/dev/zero of=" & quoted form of dummyFilePath & " bs=1024 count=" & totalSize & " >/dev/null 2>&1"
                end if
                
                -- Unmount the disk image
                do shell script "hdiutil detach " & quoted form of destinationPath

                tell application "Finder"
		            open (homeFolderPath as POSIX file)
	            end tell

                display dialog "Your Schrödinger Box has been created." buttons {"OK"} default button "OK"
				
				tell application "Superposition"
    				quit
				end tell
                
                --return input
            else
                display dialog "Passwords do not match. Please try again."
            end if
        else
            display dialog "Password entry canceled."
        end if
    else
        display dialog "Password entry canceled."
    end if
    
    --return input
end run
