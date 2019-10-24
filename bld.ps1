Set-StrictMode -Version 1.0
Set-PSDebug -Trace 1
$ErrorActionPreference = "stop"

$stage = "$($Env:PREFIX)"

# This function is a poor-man's reimplementation of "gunzip"
Function DeGZip-File{
    Param(
        $infile,
        $outfile = ($infile -replace '\.gz$','')
        )
    Set-PSDebug -Off
    $input = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
    $buffer = New-Object byte[](1024)
    while($true){
        $read = $gzipstream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
        }
    $gzipStream.Close()
    $output.Close()
    $input.Close()
    Set-PSDebug -Trace 1
}

# # Set up vcpkg and ensure modules are installed
# Set-Location C:\tools\vcpkg
# git rev-parse HEAD
# if ($LastExitCode -ne 0) { exit $LastExitCode }
# git checkout $env:VCPKG_COMMIT
# if ($LastExitCode -ne 0) { exit $LastExitCode }
# .\bootstrap-vcpkg.bat
# if ($LastExitCode -ne 0) { exit $LastExitCode }
# vcpkg integrate install
# if ($LastExitCode -ne 0) { exit $LastExitCode }
# vcpkg install boost-filesystem:x64-windows-static boost-program-options:x64-windows-static boost-thread:x64-windows-static boost-python:x64-windows-static eigen3:x64-windows-static boost-dll:x64-windows-static
# if ($LastExitCode -ne 0) 

# Validate conda Python environment
python -V
if ($LastExitCode -ne 0) { exit $LastExitCode }
python -c 'import sys; print(sys.path)'
if ($LastExitCode -ne 0) { exit $LastExitCode }

# This is used to create "chipdb" files
# vcpkg install boost-filesystem:x64-windows boost-program-options:x64-windows boost-thread:x64-windows boost-python:x64-windows eigen3:x64-windows boost-dll:x64-windows
# cmake -DCMAKE_TOOLCHAIN_FILE=c:/tools/vcpkg/scripts/buildsystems/vcpkg.cmake -DARCH=ice40 -DICEBOX_ROOT=C:/Users/smc/Miniconda3/envs/nextpnr-ice40-build/share/icebox -DVCPKG_TARGET_TRIPLET=x64-windows -G "Visual Studio 16 2019" -A "x64" -DPYTHON_EXECUTABLE=C:/Users/smc/Miniconda3/envs/nextpnr-ice40-build/python.exe -DBUILD_GUI=OFF -DSTATIC_BUILD=OFF .

# Extract the chipdb files to the source file directory.
# These files contain lots of redundant information, so we must compress them to fit them
# in the git repositry.
mkdir $env:SRC_DIR\chipdb-extract
DeGZip-File "$($env:RECIPE_DIR)\chipdb\chipdb-1k.bba.gz" "$($env:SRC_DIR)\chipdb-extract\chipdb-1k.bba"
DeGZip-File "$($env:RECIPE_DIR)\chipdb\chipdb-384.bba.gz" "$($env:SRC_DIR)\chipdb-extract\chipdb-384.bba"
DeGZip-File "$($env:RECIPE_DIR)\chipdb\chipdb-5k.bba.gz" "$($env:SRC_DIR)\chipdb-extract\chipdb-5k.bba"
DeGZip-File "$($env:RECIPE_DIR)\chipdb\chipdb-8k.bba.gz" "$($env:SRC_DIR)\chipdb-extract\chipdb-8k.bba"
DeGZip-File "$($env:RECIPE_DIR)\chipdb\chipdb-u4k.bba.gz" "$($env:SRC_DIR)\chipdb-extract\chipdb-u4k.bba"
$chipdb = "$($env:SRC_DIR.replace("\", "/"))/chipdb-extract"

# Configure and build it
cmake -DCMAKE_TOOLCHAIN_FILE=c:/tools/vcpkg/scripts/buildsystems/vcpkg.cmake -DARCH=ice40 "-DPREGENERATED_BBA_PATH=$chipdb" "-DCMAKE_INSTALL_PREFIX=$stage" -DVCPKG_TARGET_TRIPLET=x64-windows-static -G "Visual Studio 16 2019" -A "x64" -DBUILD_GUI=OFF -DSTATIC_BUILD=ON .
if ($LastExitCode -ne 0) { exit $LastExitCode }

cmake --build . --target install --config Release
if ($LastExitCode -ne 0) { exit $LastExitCode }
