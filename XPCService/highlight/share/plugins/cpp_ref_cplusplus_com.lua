--[[
Sample plugin file for highlight 3.9
]]

Description="Add cplusplus.com reference links to HTML, LaTeX, RTF and ODT output of C and C++ code"

Categories = {"c++", "html", "rtf", "latex", "odt" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if desc~="C and C++" then
    return
  end

  function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
      return set
  end

  string_items = Set {"string" ,  "u16string", "u32string"}

  stl_items = Set {"array", "bitset", "deque", "forward_list", "list",
    "map", "multimap", "multiset", "priority_queue", "queue", "set", "stack",
    "unordered_map", "unordered_multimap", "unordered_multiset", "unordered_set",
    "vector" }

  algorithm_items = Set {"adjacent_find", "all_of", "any_of","binary_search", "copy",
    "copy_backward", "copy_if", "copy_n", "count", "count_if", "equal", "equal_range", "fill", "fill_n",
    "find", "find_end", "find_first_of", "find_if", "find_if_not", "for_each", "generate",
    "generate_n", "includes", "inplace_merge", "is_heap", "is_heap_until", "is_partitioned",
    "is_permutation", "is_sorted", "is_sorted_until","iter_swap",
    "lexicographical_compare", "lower_bound", "make_heap", "max", "max_element",
    "merge", "min", "minmax", "minmax_element", "min_element", "mismatch", "move", "move-backward",
    "next_permutation", "none_of", "nth_element",
    "partial_sort", "partial_sort_copy", "partition", "partition_copy", "partition_point", "pop_heap",
    "prev_permutation", "push_heap", "random_shuffle", "remove", "remove_copy",
    "remove_copy_if", "remove_if", "replace", "replace_copy", "replace_copy_if",
    "replace_if", "reverse", "reverse_copy", "rotate", "rotate_copy", "search",
    "search_n", "set_difference", "set_intersection", "set_symmetric_difference",
    "set_union", "shuffle", "sort", "sort_heap", "stable_partition", "stable_sort", "swap",
    "swap_ranges", "transform", "unique", "unique_copy", "upper_bound" }

  clib_items = Set {"cassert", "cctype", "cerrno", "cfloat", "ciso646",
    "climits", "clocale", "cmath", "csetjmp", "csignal", "cstdarg", "cstddef",
    "cstdio ", "cstdlib", "cstring", "ctime"}

  iostream_items=Set {
    "filebuf", "fstream", "ifstream", "ios", "iostream", "ios_base", "istream",
    "istringstream", "ofstream", "ostream", "ostringstream", "streambuf",
    "stringbuf", "stringstream", "cerr", "cin", "clog", "cout", "fpos", "streamoff",
    "streampos", "streamsize"
  }

  chrono_items=Set {
    "duration",  "duration_values","high_resolution_clock","steady_clock","system_clock","time_point"
  }

  codecvt_items=Set {
    "codecvt_utf16","codecvt_utf8","codecvt_utf8_utf16"
  }

  random_items=Set {
    "bernoulli_distribution", "binomial_distribution", "cauchy_distribution", "chi_squared_distribution",
    "discrete_distribution", "exponential_distribution", "extreme_value_distribution",
    "fisher_f_distribution", "gamma_distribution", "geometric_distribution", "lognormal_distribution",
    "negative_binomial_distribution", "normal_distribution", "piecewise_constant_distribution",
    "piecewise_linear_distribution", "poisson_distribution", "student_t_distribution", "uniform_int_distribution",
    "uniform_real_distribution", "weibull_distribution"
  }

  ratio_items=Set {
    "ratio_add", "ratio_divide", "ratio_equal", "ratio_greater", "ratio_greater_equal", "ratio_less",
    "ratio_less_equal", "ratio_multiply", "ratio_not_equal", "ratio_subtract"
  }

  regex_items=Set {
    "basic_regex", "match_results", "regex_error", "regex_iterator", "regex_token_iterator", "regex_traits",
    "sub_match", "cmatch", "csub_match", "regex", "smatch", "ssub_match", "wcmatch", "wcsub_match",
    "wregex", "wsmatch", "wssub_match", "regex_replace", "regex_match", "regex_search"
  }

  system_error_items=Set {
      "error_category", "error_code", "error_condition", "is_error_code_enum", "is_error_condition_enum",
    "system_error", "errc", "generic_category", "make_error_code", "make_error_condition", "system_category"
  }

  tuple_items=Set {
    "tuple", "tuple_element", "tuple_size", "uses_allocator", "forward_as_tuple", "get", "make_tuple", "swap", "tie", "tuple_cat", "ignore"
  }

  type_traits_items=Set {
    "false_type", "integral_constant", "true_type", "alignment_of", "extent", "has_virtual_destructor", "is_abstract", "is_arithmetic", "is_array",
  "is_assignable", "is_base_of", "is_class", "is_compound", "is_const", "is_constructible", "is_convertible", "is_copy_assignable",
  "is_copy_constructible", "is_default_constructible", "is_destructible", "is_empty", "is_enum", "is_floating_point", "is_function",
  "is_fundamental", "is_integral", "is_literal_type", "is_lvalue_reference", "is_member_function_pointer", "is_member_object_pointer",
  "is_member_pointer", "is_move_assignable", "is_move_constructible", "is_nothrow_assignable", "is_nothrow_constructible", "is_nothrow_copy_assignable",
  "is_nothrow_copy_constructible", "is_nothrow_default_constructible", "is_nothrow_destructible", "is_nothrow_move_assignable", "is_nothrow_move_constructible",
  "is_object", "is_pod", "is_pointer", "is_polymorphic", "is_reference", "is_rvalue_reference", "is_same", "is_scalar", "is_signed", "is_standard_layout",
  "is_trivial", "is_trivially_assignable", "is_trivially_constructible", "is_trivially_copyable", "is_trivially_copy_assignable", "is_trivially_copy_constructible",
  "is_trivially_default_constructible", "is_trivially_destructible", "is_trivially_move_assignable", "is_trivially_move_constructible", "is_union", "is_unsigned",
  "is_void", "is_volatile", "rank", "add_const", "add_cv", "add_lvalue_reference", "add_pointer", "add_rvalue_reference", "add_volatile", "aligned_storage",
  "aligned_union", "common_type", "conditional", "decay", "enable_if", "make_signed", "make_unsigned", "remove_all_extents", "remove_const", "remove_cv",
  "remove_extent", "remove_pointer", "remove_reference", "remove_volatile", "result_of", "underlying_type"

  }

  function getURL(token, cat)
    url='http://www.cplusplus.com/reference/'..cat.. '/' .. token .. '/'

    if (HL_OUTPUT== HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      return '<a class="hl" target="new" href="' .. url .. '">'.. token .. '</a>'
    elseif (HL_OUTPUT == HL_FORMAT_LATEX) then
      return '\\href{'..url..'}{'..token..'}'
    elseif (HL_OUTPUT == HL_FORMAT_RTF) then
      return '{{\\field{\\*\\fldinst HYPERLINK "'..url..'" }{\\fldrslt\\ul\\ulc0 '..token..'}}}'
    elseif (HL_OUTPUT == HL_FORMAT_ODT) then
      return '<text:a xlink:type="simple" xlink:href="'..url..'">'..token..'</text:a>'
    end
  end

  function Decorate(token, state)

    if (state ~= HL_STANDARD and state ~= HL_KEYWORD and state ~=HL_PREPROC) then
      return
    end

    if string_items[token] then
      return  getURL(token, 'string')
    elseif stl_items[token] then
      return  getURL(token, 'stl')
    elseif algorithm_items[token] then
      return  getURL(token, 'algorithm')
    elseif clib_items[token] then
      return  getURL(token, 'clibrary')
    elseif iostream_items[token] then
      return  getURL(token, 'iostream')
    elseif chrono_items[token] then
      return  getURL(token, 'chrono')
    elseif codecvt_items[token] then
      return  getURL(token, 'codecvt')
    elseif random_items[token] then
      return  getURL(token, 'random')
    elseif ratio_items[token] then
      return  getURL(token, 'ratio')
    elseif regex_items[token] then
      return  getURL(token, 'regex')
    elseif system_error_items[token] then
      return  getURL(token, 'system_error')
    elseif tuple_items[token] then
      return  getURL(token, 'tuple')
    elseif type_traits_items[token] then
      return  getURL(token, 'type_traits')
    end

  end
end


function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="a.hl, a.hl:visited {color:inherit;font-weight:inherit;}"
  elseif (HL_OUTPUT==HL_FORMAT_LATEX) then
    Injections[#Injections+1]="\\usepackage[colorlinks=false, pdfborderstyle={/S/U/W 1}]{hyperref}"
  end
end

--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
