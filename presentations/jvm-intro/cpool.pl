#!/bin/env perl

use Encode;
sub new {
  shift;
  open my $fh, '<&STDIN';
  bless \$fh, __PACKAGE__;
}

{
  my $buf;
  sub u1 { read(${scalar shift}, $buf, 1); unpack('C', $buf); }
  sub u2 { read(${scalar shift}, $buf, 2); unpack('n', $buf); }
  sub u4 { read(${scalar shift}, $buf, 4); unpack('N', $buf); }
  sub f4 { read(${scalar shift}, $buf, 4); unpack('f', $buf); }
  sub l8 { my $o=shift; $o->u4 << 32 + $o->u4 }
  sub d8 { read(${scalar shift}, $buf, 8); unpack('D', $buf); }
  sub data {
    my ($o, $n) = @_;
    read($$o, $buf, $n);
    return $buf;
  }
  sub utf8 {
    my ($o, $n) = @_;
    read($$o, $buf, $n);
    return decode('utf8', $buf);
  }
}
my %cp_tag = (
  CONSTANT_Class              => 7,
  CONSTANT_Fieldref           => 9,
  CONSTANT_Methodref          => 10,
  CONSTANT_InterfaceMethodref => 11,
  CONSTANT_String             => 8,
  CONSTANT_Integer            => 3,
  CONSTANT_Float              => 4,
  CONSTANT_Long               => 5,
  CONSTANT_Double             => 6,
  CONSTANT_NameAndType        => 12,
  CONSTANT_Utf8               => 1,
  CONSTANT_MethodHandle       => 15,
  CONSTANT_MethodType         => 16,
  CONSTANT_InvokeDynamic      => 18,
);
my %cp_name = reverse %cp_tag;

sub cpool {
  my $o = shift;

  my $n = $o->u2 - 1;

  my @cp = ();
  my $tag;
  my %cpf = (
    CONSTANT_Class              => sub { tag => $tag,       name_index => $o->u2 },
    CONSTANT_Fieldref           => sub { tag => $tag,      class_index => $o->u2, name_and_type_index => $o->u2 },
    CONSTANT_Methodref          => sub { tag => $tag,      class_index => $o->u2, name_and_type_index => $o->u2 },
    CONSTANT_InterfaceMethodref => sub { tag => $tag,      class_index => $o->u2, name_and_type_index => $o->u2 },
    CONSTANT_String             => sub { tag => $tag,     string_index => $o->u2 },
    CONSTANT_Integer            => sub { tag => $tag,            value => $o->u4 },
    CONSTANT_Float              => sub { tag => $tag,            value => $o->f4 },
    CONSTANT_Long               => sub { tag => $tag,            value => $o->l8 },
    CONSTANT_Double             => sub { tag => $tag,            value => $o->d8 },
    CONSTANT_NameAndType        => sub { tag => $tag,       name_index => $o->u2,   descriptor_index => $o->u2 },
    CONSTANT_Utf8               => sub { tag => $tag,            value => $o->utf8($o->u2) },
    CONSTANT_MethodHandle       => sub { tag => $tag,   reference_kind => $o->u1,    reference_index => $o->u2 },
    CONSTANT_MethodType         => sub { tag => $tag,  descriptor_index => $o->u2 },
    CONSTANT_InvokeDynamic      => sub { tag => $tag,  bootstrap_method_attr_index => $o->u2, name_and_type_index => $o->u2 },
  );
  for my $i ( 1 .. $n ) {
    $tag = $o->u1;
    $cp[$i] = { $cpf{$cp_name{$tag}}->() };
  }
  return \@cp;
}

sub attr_info {
  my ($o, $i, $cp) = shift;
  my %attr  = (
    ConstantValue =>   sub { constantvalue_length => $o->u4, constantvalue_index => $o->u2 },
    Code          =>   sub {  },
    StackMapTable =>   sub {  },
    Exceptions    =>   sub {  },
    InnerClasses  =>   sub {  },
    EnclosingMethod =>   sub {  },
    Synthetic     =>   sub {  },
    Signature     =>   sub {  },
    SourceFile    =>   sub {  },
    SourceDebugExtension  =>   sub {  },
    LineNumberTable =>   sub {  },
    LocalVariableTable  =>   sub {  },
    LocalVariableTypeTable =>   sub {  },
    Deprecated  =>    sub {  },
    RuntimeVisibleAnnotations  =>    sub {  },
    RuntimeInvisibleAnnotations  =>    sub {  },
    RuntimeInvisibleAnnotations  =>    sub {  },
    RuntimeInvisibleParameterAnnotations  =>    sub {  },
    AnnotationDefault  =>    sub {  },
    BootstrapMethods  =>    sub {  },
  );
}

sub attributes {
  my $o = shift;
  my @attributes = ();
  my $n = $o->u2;
  for ( 1 .. $n ) {
    my %attr = ( attribute_name_index => $o->u2, attribute_length => $o->u4 );
    $attr{attribute_data} = $o->data( $attr{attribute_length} );
    push @attributes, \%attr;
  }
  return \@attributes;
}

sub members {
  my $o = shift;

  my $n = $o->u2;
  my @members = ();
  for ( 1 .. $n ) {
    my %m = (
      access_flags => $o->u2,
      name_index => $o->u2,
      descriptor_index => $o->u2,
    );
    $m{attributes} = $o->attributes;
    push @members, \%m;
  }
  return \@members;
}

sub parse {
  my $o = shift;
  my %c = (
    magic => $o->u4,
    minor => $o->u2,
    major => $o->u2,
  );

  $c{cpool} = $o->cpool;

  $c{access_flags} = $o->u2;
  $c{this_class}   = $o->u2;
  $c{super_class}  = $o->u2;

  # interfaces
  my $n_intf = $o->u2;
  my @intf = ();
  for ( 1 .. $n_intf ) {
    push @intf, $o->u2;
  }

  # fields
  $c{fields} = $o->members;

  # methods
  $c{methods} = $o->members;

  # attributes
  $c{attributes} = $o->attributes;

  return \%c;
}

sub main {
  my $c = __PACKAGE__->new(STDIN);
  use Data::Dumper;
  print Dumper($c->parse);
}

if ( !caller ) { exit main(@ARGV); }
