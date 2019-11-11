# Operators are really method invocations.
a = 10
b = 3.*(a).+(2)
Kernel::printf("%d %d\n", a, b);

# Type is still dynamic.
b = String.new("A string")
c = 'Another String'
Kernel.print(b.+(" and ")::+(c).+("\n"))
