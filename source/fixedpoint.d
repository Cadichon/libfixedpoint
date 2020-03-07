module fixedpoint;

private import std.traits;
private import std.stdio;
private import std.format;
private import std.conv;
private import std.range;
private import std.algorithm;
private import std.exception;
private import std.math;

private struct FixedImpl(T, ubyte precision) if (isIntegral!(T) && precision <= T.sizeof * 8)
{
private:
  T internal;

  T binaryStringToInternalType(const(string) binString) const {
    char[] bin;
    T bits;

    if (binString.length < T.sizeof * 8) {
      bin = '0'.repeat(T.sizeof * 8 - binString.length).array ~ binString;
    }
    else
      bin = binString[$ - T.sizeof * 8 .. $].dup;
    foreach(char c; bin) {
      if (c != '0' && c != '1')
        throw new ConvException(binString ~ " is not a binary representation");
      bits = cast(T)(bits << 1);
      if (c == '1')
        bits += 1;
    }
    return bits;
  }

  T floatingTypeToInternalType(const(real) floating) const {
    if (isNaN(floating) || isInfinity(floating))
      throw new ConvException(to!string(floating) ~ " is not a valid floating point number");
    real tmp = round(floating * (2 ^^ precision));

    return cast(T)(tmp);
  }

public:

  /* Constructeur */
  this(const(typeof(this)) fixed) {
    this.internal = fixed.internal;
  }

  this(const(ulong) integer) {
    this.internal = cast(T)(integer << precision);
  }

  this(const(string) binString) {
    this.internal = binaryStringToInternalType(binString);
  }

  this(const(real) floating) {
    this.internal = floatingTypeToInternalType(floating);
  }

  /* Opérateur d'assignation */
  typeof(this) opAssign(const(typeof(this)) fixed) {
    this.internal = fixed.internal;
    return this;
  }

  typeof(this) opAssign(const(ulong) integer) {
    this.internal = cast(T)(integer << precision);
    return this;
  }

  typeof(this) opAssign(const(string) binString) {
    this.internal = binaryStringToInternalType(binString);
    return this;
  }

  typeof(this) opAssign(const(real) floating) {
    this.internal = floatingTypeToInternalType(floating);
    return this;
  }

  /* Opérateur add, sub, mul, div, mod */
  typeof(this) opBinary(string op)(const(typeof(this)) rhs) const {
    Unconst!(typeof(this)) res;

    static if (op == "+") {
      res.internal = cast(T)(cast(ulong)(this.internal) + cast(ulong)(rhs.internal));
    }
    else static if (op == "-") {
      res.internal = cast(T)(cast(ulong)(this.internal) - cast(ulong)(rhs.internal));
    }
    else static if (op == "*") {
      res.internal = cast(T)((cast(ulong)(this.internal) * cast(ulong)(rhs.internal)) / (2 ^^ precision));
    }
    else static if (op == "/") {
      res.internal = cast(T)((cast(ulong)(this.internal) * (2 ^^ precision) / cast(ulong)(rhs.internal)));
    }
    else {
      static assert(false, op ~ " not implemented for " ~ typeof(this).stringof);
    }
    return res;
  }

  typeof(this) opBinary(string op)(const(ulong) rhs) const {
    Unconst!(typeof(this)) res = rhs;

    return opBinary!(op)(res);
  }

  typeof(this) opBinary(string op)(const(string) rhs) const {
    Unconst!(typeof(this)) res;

    res.internal = binaryStringToInternalType(rhs);
    return opBinary!(op)(res);
  }

  typeof(this) opBinary(string op)(const(real) rhs) const {
    Unconst!(typeof(this)) res;

    res.internal = floatingTypeToInternalType(rhs);
    return opBinary!(op)(res);
  }

  /* Opérateur unaire (post et pre) d'addition et de soustraction */
  typeof(this) opUnary(string op)() {
    static if (op == "++") {
      this = this + 1;
    }
    else static if (op == "--") {
      this = this - 1;
    }
    else {
      static assert(false,  op ~ " not implemented for " ~ typeof(this).stringof);
    }
    return this;
  }

  /* Opérateur d'égalité */
  bool opEquals(const(typeof(this)) rhs) const {
    return this.internal == rhs.internal;
  }

  bool opEquals(const(ulong) rhs) const {
    return this.integralPart == rhs;
  }

  bool opEquals(const(string) rhs) const {
    Unconst!(typeof(this)) res;

    res.internal = binaryStringToInternalType(rhs);
    return opEquals(res);
  }

  bool opEquals(const(real) rhs) const {
    Unconst!(typeof(this)) res;

    res.internal = floatingTypeToInternalType(rhs);
    return opEquals(res);
  }

  /* Opérateur de comparaison */
  int opCmp(const(typeof(this)) rhs) const {
    return (cast(int)(this.internal - rhs.internal));
  }

  int opCmp(const(ulong) rhs) const {
    return (cast(int)(this.integralPart - rhs));
  }

  int opCmp(const(string) rhs) const {
    Unconst!(typeof(this)) res;

    res.internal = binaryStringToInternalType(rhs);
    return (cast(int)(this.internal - res.internal));
  }

  int opCmp(const(real) rhs) const {
    Unconst!(typeof(this)) res;

    res.internal = floatingTypeToInternalType(rhs);
    return (cast(int)(this.internal - res.internal));
  }

  /* Conversion */
  @property T integralPart() const {
    return cast(T)(this.internal >> precision);
  }

  @property T fractionalPart() const {
    const(uint) toShift = T.sizeof * 8 - precision;
    T fracBits = cast(T)((this.internal << toShift) >> toShift);
    real tmp = 0;
    real intPart;
    real fracPart;

    for (int i; i < precision; i += 1) {
      int pos = precision - i - 1;
      real fact = ((fracBits >> pos) & 1);

      tmp += ldexp(fact, - i - 1);
    }
    do {
      fracPart = modf(tmp, intPart);
      tmp *= 10;
    } while (fracPart != 0);
    return cast(T)(intPart);
  }

  string toString() const {
    return to!string(this.integralPart) ~ "." ~ to!string(this.fractionalPart);
  }

  string toBinary(bool addPoint = false) const {
    char[] ret;
    int i;

    for (i = T.sizeof * 8 - 1; i >= 0; i -= 1) {
      ubyte bit = cast(ubyte)((this.internal >> i) & 1);

      ret ~= cast(char)(bit + '0');
      if (addPoint && i ==  precision)
        ret ~= '.';
    }
    return ret;
  }
}

public alias fixed = FixedImpl!(ushort, 4);

fixed newton(ubyte nbRec)(fixed n) {
  static if (nbRec == 0)
    return n;
  else
    return fixed(0.5) * (newton!(nbRec - 1)(n) + (n / newton!(nbRec - 1)(n)));
}

unittest {
  import std.stdio;

  writeln("Testing default initialisation, copy construction and copy assignation");
  fixed test;
  fixed test2 = 42;
  fixed test3 = test2;
  assert(test == 0);
  test = test3;
  assert(test == test2 && test2 == test3 && test3 == 42);
}

unittest {
  import std.stdio;

  writeln("Testing int initialisation and assignment");
  writeln("\tfixed test = 42");
  fixed test = 42;
  writefln("\ttest == %s", test);
  assert(test == 42);
}

unittest {
  import std.stdio;

  writeln("Testing binary string initialisation and assignment");
  writeln("\tfixed test = \"1010100000\"");
  fixed test = "1010100000";
  writefln("\ttest == %s", test);
  assert(test == 42.0);
}

unittest {
  import std.stdio;

  writeln("Testing float initialisation and assignment");
  writeln("\tfixed test = 42.5");
  fixed test = 42.5;
  writefln("\ttest == %s", test);
  assert(test == 42.5);
  writeln("\tfixed test = 68.2");
  fixed test2 = 68.2;
  writefln("\ttest2 == %s", test2);
  assert(test2 == 68.1875);
  writeln("\t\\\\precision problem expected, a 4 bits fractionnal part can't stock 0.2, 0.1875 is the closest thing it can handle");
}

unittest {
  import std.stdio;

  writeln("Testing addition");
  writefln("\tfixed(42) + fixed(2) == %s", fixed(42) + fixed(2));
  assert(fixed(42) + fixed(2) == fixed(44));
  writefln("\tfixed(42) + fixed(\"1010101000\") == %s", fixed(42) + fixed("1010101000"));
  assert(fixed(42) + fixed("1010101000") == 84.5);
  writeln("\tfixed(42) + 2.5 == %s", fixed(42) + 2.5);
  assert(fixed(42) + 2.5 == 44.5);
}

unittest {
  import std.stdio;

  writeln("Testing substraction");
  writefln("\tfixed(84) - fixed(42) == %s", fixed(84) - fixed(42));
  assert(fixed(84) - fixed(42) == fixed(42));
  writefln("\tfixed(42.625) - fixed(0.625) == %s", fixed(42.625) - fixed(0.625));
  assert(fixed(42.625) - fixed(0.625) == 42);
}

unittest {
  writeln("Testing multiplication");
  writefln("\tfixed(82) * fixed(42.5) == %s", fixed(82) * fixed(42.5));
  assert(fixed(82) * fixed(42.5) == 3485);
  writefln("\tfixed(\"10000\") * fixed(\"1010100100\") == %s", fixed("10000") * fixed("1010100100"));
  assert(fixed("10000") * fixed("1010100100") == "1010100100");
  writefln("\tfixed(\"110000\") * fixed(\"1010100100\") == %s", fixed("110000") * fixed("1010100100"));
  assert(fixed("110000") * fixed("1010100100") == "11111101100");
  writefln("\tfixed(1) * fixed(42.25) == %s", fixed(1) * fixed(42.25));
  assert(fixed(1) * fixed(42.25) == fixed(42.25));
  writefln("\tfixed(3) * fixed(42.25) == %s", fixed(3) * fixed(42.25));
  assert(fixed(3) * fixed(42.25) == fixed(126.75));
}

unittest {
  writeln("Testing division");
  assert(fixed(15) / fixed(15) == 1);
  writefln("\tfixed(15) / fixed(15) == %s", fixed(15) / fixed(15));
  assert(fixed(42) / fixed(3) == 14);
  writefln("\tfixed(42) / fixed(3) == %s", fixed(42) / fixed(3));
  assert(fixed(42) / fixed(3.5) == 12);
  writefln("\tfixed(42) / fixed(3.5) == %s", fixed(42) / fixed(3.5));

}

unittest {
  writeln("Testing newton");
  assert(newton!(0)(fixed(15)) == 15);
  assert(newton!(1)(fixed(15)) == 8);
  assert(newton!(2)(fixed(15)) == 4.9375);
  assert(newton!(3)(fixed(15)) == 3.9375);
  assert(newton!(4)(fixed(15)) == 3.8125);
  assert(newton!(5)(fixed(15)) == 3.8125);

  writefln("\tnewton!(0)(fixed(15)) = %s", newton!(0)(fixed(15)));
  writefln("\tnewton!(1)(fixed(15)) = %s", newton!(1)(fixed(15)));
  writefln("\tnewton!(2)(fixed(15)) = %s", newton!(2)(fixed(15)));
  writefln("\tnewton!(3)(fixed(15)) = %s", newton!(3)(fixed(15)));
  writefln("\tnewton!(4)(fixed(15)) = %s", newton!(4)(fixed(15)));
  writefln("\tnewton!(5)(fixed(15)) = %s", newton!(5)(fixed(15)));
}


unittest {
  writeln("Testing newton with fixed 32 bits with 8 bits precision");

  alias lfixed = FixedImpl!(uint, 8);

  lfixed lnewton(ubyte nbRec)(lfixed n) {
    static if (nbRec == 0)
      return n;
    else
      return lfixed(0.5) * (lnewton!(nbRec - 1)(n) + (n / lnewton!(nbRec - 1)(n)));
  }

  writefln("\tlnewton!(0)(lfixed(15)) = %s", lnewton!(0)(lfixed(15)));
  writefln("\tlnewton!(1)(lfixed(15)) = %s", lnewton!(1)(lfixed(15)));
  writefln("\tlnewton!(2)(lfixed(15)) = %s", lnewton!(2)(lfixed(15)));
  writefln("\tlnewton!(3)(lfixed(15)) = %s", lnewton!(3)(lfixed(15)));
  writefln("\tlnewton!(4)(lfixed(15)) = %s", lnewton!(4)(lfixed(15)));
  writefln("\tlnewton!(5)(lfixed(15)) = %s", lnewton!(5)(lfixed(15)));

}
unittest {
  writeln("Testing newton with fixed 64 bits with 16 bits precision");

  alias vlfixed = FixedImpl!(ulong, 16);

  vlfixed vlnewton(ubyte nbRec)(vlfixed n) {
    static if (nbRec == 0)
      return n;
    else
      return vlfixed(0.5) * (vlnewton!(nbRec - 1)(n) + (n / vlnewton!(nbRec - 1)(n)));
  }

  writefln("\tvlnewton!(0)(lfixed(15)) = %s", vlnewton!(0)(vlfixed(15)));
  writefln("\tvlnewton!(1)(lfixed(15)) = %s", vlnewton!(1)(vlfixed(15)));
  writefln("\tvlnewton!(2)(lfixed(15)) = %s", vlnewton!(2)(vlfixed(15)));
  writefln("\tvlnewton!(3)(lfixed(15)) = %s", vlnewton!(3)(vlfixed(15)));
  writefln("\tvlnewton!(4)(lfixed(15)) = %s", vlnewton!(4)(vlfixed(15)));
  writefln("\tvlnewton!(5)(lfixed(15)) = %s", vlnewton!(5)(vlfixed(15)));

}
