#!/bin/zsh

exiftool -p '$FilePath -> ${CreateDate;DateFmt("%Y-%m-%d")}/$FileName' .