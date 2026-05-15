#!/bin/zsh

exiftool -r -p '$FilePath -> ${CreateDate;DateFmt("%Y/%Y-%m-%d")}/$FileName' .