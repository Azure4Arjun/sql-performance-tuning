sqlio -kW -s60 -fsequential -o8 -b64 -LS TestFile.dat > res.txt
sqlio -kW -s60 -frandom -o8 -b64 -LS TestFile.dat > res.txt
sqlio -kR -s60 -fsequential -o8 -b64 -LS TestFile.dat > res.txt
sqlio -kR -s60 -frandom -o8 -b64 -LS TestFile.dat > res.txt
