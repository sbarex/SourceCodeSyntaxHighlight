function replace_vars(str, vars)
	-- Allow replace_vars{str, vars} syntax as well as replace_vars(str, {vars})
	if not vars then
		vars = str
		str = vars[1]
	end
	return (string_gsub(str, "({([^}]+)})",
		function(whole,i)
			return vars[i] or whole
		end))
end

-- Example:
output = replace{
		[[Hello {name}, welcome to {company}. ]],
		name = name,
		company = get_company_name()
}
