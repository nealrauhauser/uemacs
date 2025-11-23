on open theFiles
    tell application "Terminal"
        set wasRunning to running
        activate
        
        -- Wait briefly if we need to catch the default window on startup
        if not wasRunning then delay 0.5
        
        repeat with i from 1 to count of theFiles
            set aFile to item i of theFiles
            set filePath to POSIX path of aFile
            
            set newTab to missing value
            
            -- If Terminal just started, use the default empty window for the first file
            if i is 1 and not wasRunning and (count of windows) > 0 then
                try
                    set targetWindow to front window
                    if (count of tabs of targetWindow) is 1 and not (busy of selected tab of targetWindow) then
                        set newTab to selected tab of targetWindow
                    end if
                end try
            end if
            
            -- If we didn't reuse a window, create a new one (start with empty shell)
            if newTab is missing value then
                set newTab to do script ""
            end if
            
            -- Get the window ID for robust closing
            set targetWindow to (first window whose tabs contains newTab)
            set winID to id of targetWindow
            
            -- Construct command: Run 'me', then force close the window
            -- We use 'ignoring application responses' and 'saving no' to try and bypass the prompt
            set cmd to "exec bash -c '/usr/local/bin/me " & quoted form of filePath & "; osascript -e \"ignoring application responses\" -e \"tell application \\\"Terminal\\\" to close window id " & winID & " saving no\" -e \"end ignoring\"'"
            
            -- Execute the command
            do script cmd in newTab
            
            -- Apply settings to the tab
            set current settings of newTab to settings set "Basic"
            
            -- Resize the window containing the new tab
            tell (first window whose tabs contains newTab)
                -- Set bounds to left half of 3200x1800 screen: {left, top, right, bottom}
                -- Adjusted top to 25 to account for menu bar
                set bounds to {0, 25, 1600, 1800}
            end tell
        end repeat
    end tell
end open
