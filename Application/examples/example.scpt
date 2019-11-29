display alert "Hello, world!" buttons {"Rudely decline", "Happily accept"}
set theAnswer to button returned of the result
if theAnswer is "Happily accept" then
	beep 5
else
	say "Piffle!"
end if
