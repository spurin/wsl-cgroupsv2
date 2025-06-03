## Windows WSL Users

> 🎉 **Great news!**
> Since **WSL version 2.5.1**, Microsoft has made **cgroupsv2 the standard**, just like most modern Linux distributions!  
> This means you no longer need to manually tweak wsl config files to get Docker + Kubernetes playing nicely together on Windows.  
> Simply **update WSL**, then head straight to [Check your configuration](#check-your-configuration) ✅

### Update WSL

Docker Desktop for Windows makes use of the WSL (Windows Subsystem for Linux) environment as the Linux Kernel.  For Kubernetes to work as expected within Docker Desktop when running within a container, it is important to run a modern Kernel.

Install and/or Update the version of wsl by executing the following from a Command Prompt or via Powershell, complete any steps that follow -

```
wsl --install
wsl --update
```

After updating check your WSL version by running -

```
wsl --version
```

I recommend being on a version equal or greater than `WSL version: wsl.2.5.1` and `Kernel version: 6.6`

### Configure WSL to use cgroupsv2 (only required for WSL versions before v2.5.1)

Over the years, Linux has embarked on a transition journey towards cgroupsv2. This has become the baseline for many Linux-based distributions, and this holds true for Docker Desktop on Mac and Linux as well. However, there's a slight hitch when it comes to Windows Subsystem for Linux (WSL). WSL previously operated in a hybrid mode that supported both cgroupsv1 and cgroupsv2 in WSL versions prior to v2.5.1.

This dual support system introduces problems when running containers that utilize cgroupsv2.

A key issue emerges with the process manager, systemd, which runs on cgroupsv1 while the main system is operating on cgroupsv2. This discrepancy creates numerous issues for many Kubernetes distributions. With the deprecation and withdrawal of support for cgroupsv1 on the horizon, there's a need to rectify this situation from a WSL standpoint to achieve consistency.

Luckily, WSL comes with a configuration file that provides an option to set Kernel parameters. Leveraging this, we can disable cgroupsv1 in older versions, thereby aligning the WSL environment with modern Linux distributions.

Implementing this change is straightforward. It's simply a matter of creating or editing a text file at `%USERPROFILE%\.wslconfig` (i.e. for my user of James, this would be `C:\Users\James\.wslconfig`). 

A friendly way of doing this is by pasting the following into the explorer bar - `notepad.exe %UserProfile%/.wslconfig`

Specifically, you need to add the following lines:

```
[wsl2]
kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1
```

To save the file, select "Save As" and update it with double quotes, as ".wslconfig" to avoid Windows from appending a default .txt extension automatically. After saving, execute the command `wsl --shutdown` to restart WSL.

*n.b. if you were already running Docker Desktop, you may need to manually restart it after executing a `wsl --shutdown`, the Restart Popup from Docker does not always work*

To revert, the file can be removed or updated and again, WSL can be restarted by running `wsl --shutdown`

To automate the setup of this process, the following can be pasted into a powershell prompt, this will create a backup of the file if it exists, modify/add the entry and then restart WSL -

```
# Read the file if it exists
if (Test-Path $env:USERPROFILE\.wslconfig) {
    $fileContent = Get-Content -Path $env:USERPROFILE\.wslconfig
    # Create a timestamp-based backup
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Copy-Item -Path $env:USERPROFILE\.wslconfig -Destination "$env:USERPROFILE\.wslconfig.$timestamp.backup"
} else {
    $fileContent = @()
}

# Check if [wsl2] section exists
$wslSectionExists = $fileContent -match "\[wsl2\]"

# Check if specific line exists
$lineExists = $fileContent -match "kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1"

if ($wslSectionExists -and $lineExists) {
    Write-Output "The configuration is already set."
} elseif ($wslSectionExists -and -not $lineExists) {
    Add-Content -Path $env:USERPROFILE\.wslconfig -Value "kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1"
    Write-Output "The configuration has been updated. Shutting down WSL..."
    wsl --shutdown
} else {
    Add-Content -Path $env:USERPROFILE\.wslconfig -Value "`n[wsl2]`nkernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1"
    Write-Output "The configuration has been set. Shutting down WSL..."
    wsl --shutdown
}
```

*Again - n.b. if you were already running Docker Desktop, you may need to manually restart it after executing a `wsl --shutdown`, the Restart Popup from Docker does not always work*

### Install/Update Docker Desktop

Install the latest version of Docker Desktop, this process has been tested and is known to work well with Docker Desktop from `v4.21.1` onwards.

### Check your configuration

With WSL updated, and the latest version of Docker Desktop installed, run the following command from a command prompt.  It will run a container and verify that the container is using cgroupsv2 as expected -

```
% docker run -it --rm spurin/wsl-cgroupsv2:latest
Success: cgroup type is cgroup2fs
```

If you see tmpfs or another value, please re-check the configuration above.

### Thanks

Thanks to [@nunix](https://github.com/nunix) [@mark-duggan](https://github.com/mark-duggan) and [@geoffreybaldry](https://github.com/geoffreybaldry) for support in troubleshooting Kubernetes in a container in Windows and modifying WSL 🚀
