# PowerShell Proof-of-Concept Converter / File Encoder

These 2 scripts are used to encode files in other files.


## Converters - ConvertFrom-HeaderBlock / ConvertTo-HeaderBlock

These 2 functions are used to include a file (scripts, binary, etc) as a resource in another text file. The latter is represented as a text header like this:

```
  <# === BEGIN EMBEDDED FILE HEADER === 
  H 4 s I A A A A A A A A C p 1 W X U / b M B R 9 r 9 T / c F V V a q K R a H t
  F q g S U d m J j r K I V L 6 x C J r l t g l y 7 2 A 5 d B f z 3 X T s f N Q
  y I h 0 C D 6 j M V E Y W q Q S t R a m x a T t / A F v B l 2 7 4 C A A A
  === END EMBEDDED FILE HEADER === #>
```

### How does it work ?

#### Include a resource in a file

The function ```ConvertTo-HeaderBlock``` takes a file path, then:

1. will get all the characters with encoding 'UTF8', and convert them to a byte array
2. compress the byte array using GZIP
3. convert the data to Base 64 for text representation
4. split the data in similar subgroups to have a pretty header block

All you need to do afterwards is to include that block of text whereever you want in the file of your choice.

***NOTE THAT WHEN YOU EXTRACT THE DATA FROM THE FILE IT WAS INCLUDED IN, THE LOCATION OF THE TEXT BLOCK IS NOT IMPORTANT, CAN BE AT THE BEGINNING, MID or END OF FILE...***

#### Retrieve a resoure from a file


The function ```ConvertFrom-HeaderBlock``` takes a file path, then:

1. locate the text block that contains the resource in the file specified.
2. convert Base64 to byte array
3. decompress the bytes using GZIP
4. convert back to text
