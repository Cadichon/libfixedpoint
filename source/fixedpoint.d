module fixedpoint;

private import std.traits : isIntegral;
private import std.stdio : writeln;
private import std.format : sformat;
private import std.conv : to;


/*
  TODO: Documentation
*/
private struct FixedImpl(T, ubyte precision) if (isIntegral!(T) && precision <= T.sizeof * 8)
{
private:
  T internal;

public:
  this(long integer) {
    this.internal = cast(T)(integer << precision);
  }

  typeof(this) opAssign(long integer) {
    this.internal = cast(T)(integer << precision);
    return this;
  }

  typeof(this) opBinary(string op)(typeof(this) rhs) {
    typeof(this) ret;

    static if (op == "+") {
      res.internal = this.internal + rhs.internal;
    }
    else static if (op == "-") {
      res.internal = this.internal - rhs.internal;
    }
    /*
      TODO: implement *, / and %
    */
    else {
      static assert(false, op ~ " not implemented");
    }
    return res;
  }

  typeof(this) opUnary(string op)() {
    static if (op == "++") {
      this = this + 1;
    }
    else static if (op == "--") {
      this = this - 1;
    }
    else {
      static assert(false, " not implemented");
    }
    return this;
  }

  @property T integralPart() {
    return cast(T)(this.internal >> precision);
  }

  @property T fractionalPart() {
    return cast(T)(this.internal << (T.sizeof * 8 - precision));
  }

  string toBinary() {
    char[T.sizeof * 8] buf;
    return sformat!("%0*b")(buf, T.sizeof * 8, this.internal);
  }

  string toString() {
    return to!string(this.integralPart) ~ "." ~ to!string(this.fractionalPart);
  }
}

unittest {

  /*
    TODO: Yes. unit test...
  */
}

public alias sfixed = FixedImpl!(short, 4);
public alias usfixed = FixedImpl!(ushort, 4);
public alias fixed = FixedImpl!(int, 8);
public alias ufixed = FixedImpl!(uint, 8);
public alias lfixed = FixedImpl!(long, 16);
public alias ulfixed = FixedImpl!(ulong, 16);
