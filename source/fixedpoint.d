module fixedpoint;

private import std.traits : isIntegral;
private import std.stdio : writeln;

struct FixedImpl(T, ubyte precision) if (isIntegral!(T) && precision <= T.sizeof * 8)
{}

alias fixed = FixedImpl!(short, 4);
alias ufixed = FixedImpl!(ushort, 4);
