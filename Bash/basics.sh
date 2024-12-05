# chmod +x 
wsl specific? -> give file permission to be executed oder so 
# Modify the permissions of certain shell script files with chmod +x to make them executable

#! !!!!!!! GET INFO ABOUT ANY BASH COMMAND
man <any bash command>

# get meta data about file
stat <file>

# delete empty directory
rmdir directoryname

# delete directory with files in it
rm -rf directoryname

# list all files/directories (including HIDDEN ones)
ls -a

# list more details and make it human-readable
ls -l -h

#! PIPES | => pipe the output of one command on to another command
# e.g.
cat error.log | sort | uniq

#! print PATH env variable
cat /etc/environment
# PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

# search through text
grep "word" hello.txt

# modify text
echo "word" | sed "s/j/m/g"

# make files smaller
gzip

