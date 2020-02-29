module fixedpoint;

private import std.traits;
private import std.stdio;
private import std.format;
private import std.conv;
private import std.range;
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
    real tmp = floating * (1 << precision);
    T ret = cast(T)(tmp);

    return ret;
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
    Unconst!(typeof(this)) res; //this est constant a cause du const de la methode, Unconst permet de déclarer une variable du même type que this, mais non constant

    static if (op == "+") {
      res.internal = cast(T)(this.internal + rhs.internal);
    }
    else static if (op == "-") {
      res.internal = cast(T)(this.internal - rhs.internal);
    }
    else static if (op == "*") {
      res.internal = cast(T)((this.internal * rhs.internal) >> precision);
    }
    /*
      TODO: implement /
    */
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
      real fact = (fracBits & (1 << pos)) >> pos;

      tmp += ldexp(fact, - i - 1);
    }
    do {
      fracPart = modf(tmp, intPart);
      tmp *= 10;
    } while (fracPart < 0);
    return cast(T)(tmp);
  }

  string toString() const {
    return to!string(this.integralPart) ~ "." ~ to!string(this.fractionalPart);
  }
}

public alias fixed = FixedImpl!(ushort, 4);

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
  fixed test = 42;
  assert(test == 42);
}

unittest {
  import std.stdio;

  writeln("Testing binary string initialisation and assignment");
  fixed test = "1010100000";
  assert(test == 42);
}

unittest {
  import std.stdio;

  writeln("Testing float initialisation and assignment");
  fixed test = 42.0f;
  assert(test == 42); //Conversion très imprécise pour les nombre "vraiment" flottant
}

unittest {
  import std.stdio;

  writeln("Testing addition");
  fixed test = 42;
  fixed test2 = "1010101000"; //42.5
  assert(test + 2 == 44);
  assert((test + "1010101000").toString == "84.5");
  assert(test + 2f == 44); //Conversion très imprécise pour les nombre "vraiment" flottant
}

unittest {
  import std.stdio;

  writeln("Testing substraction");
  fixed test = 82;
  fixed test2 = "1010101000"; //42.5
  assert(test - 2 == 80);
  assert((test - "1010101000").toString == "39.5");
  assert(test - 2f == 80); //Conversion très imprécise pour les nombre "vraiment" flottant
}

unittest {
  fixed test = 82;
  fixed test2 = "1010101000"; //42.5
  assert(test * test2 == 3485);
  assert(fixed("10000") * fixed("1010100100")/*1 * 42.25*/ == "1010100100");
  assert(fixed("110000") * fixed("1010100100")/*3 * 42.25*/ == "11111101100" /*126.75*/);
}
