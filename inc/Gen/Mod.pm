use strict;
use warnings;
use 5.014;

package Gen::Mod {

  use Moo;
  
  has package_name => (
    is       => 'ro',
    required => 1,
  );

  foreach my $attr (qw( constants typedefs functions )) {
    has $attr => (
      is      => 'ro',
      default => sub { [] },
      lazy    => 1,
    );
  }
  
  foreach my $attr (qw( abstract synopsis description )) {
    has $attr => (
      is       => 'ro',
      required => 1,
    );
  }

  sub path
  {
    my @list = split /::/, shift->package_name;
    $list[-1] .= '.pm';
    require Path::Class::File;
    Path::Class::File->new('lib', @list);
  }
  
  sub generate
  {
    my($self) = @_;
    require Template;
    my $tt = Template->new({
      INCLUDE_PATH => 'inc/tt',
    });
    $tt->process('module.tt', { pm => $self }, $self->path.'')
      || die $tt->error;
  }
  
  sub find_function_by_name
  {
    my($self, $name) = @_;
    foreach my $function (@{ $self->functions })
    {
      return $function if $function->name eq $name;
    }
    return;
  }
  
  sub find_typedef_by_alias
  {
    my($self, $alias) = @_;
    foreach my $typedef (@{ $self->typedefs })
    {
      return $typedef if $typedef->alias eq $alias;
    }
    return;
  }

  sub lint
  {
    my($self) = @_;
    foreach my $function (sort { $a->name cmp $b->name } @{ $self->functions })
    {
      $function->lint;
    }
  }
  
}

package Gen::Constant {

  use Moo;
  
  has name => (
    is       => 'ro',
    required => 1,
  );
  
  has value => (
    is       => 'ro',
    required => 1,
  );

}

package Gen::Typedef {

  use Moo;
  
  has type => (
    is       => 'ro',
    required => 1,
  );

  has alias => (
    is       => 'ro',
    required => 1,
  );

};

package Gen::Function {

  use Moo;
  
  has name => (
    is       => 'ro',
    required => 1,
  );
  
  has return_type => (
    is       => 'rw',
    required => 1,
  );
  
  has arguments => (
    is      => 'ro',
    default => sub { [] },
    lazy    => 1,
  );
  
  sub ffi_argument_signature {
    my($self) = @_;
    join ', ', map { sprintf "'%s'", $_->type } @{ $self->arguments };
  }
  
  sub pod_usage {
    my($self) = @_;
    
    my $str = '';
    if($self->return_type ne 'void') {
      $str .= 'my $' . $self->return_type . ' = ';
    }
    
    $str .= $self->name . '(';
    
    $str .= join ', ', map {
      $_->type =~ /_array/ ? '\\@' . $_->name : '$' . $_->name
    } @{ $self->arguments };

    $str .= ")\n";
  }
  
  sub lint {
    my($self) = @_;
    if(grep { $_->name =~ /\*/ } @{ $self->arguments })
    {
      say STDERR "LINT function ", $self->name, " has unmapped pointer arguments";
    }
  }
  
};

package Gen::ArgumentType {

  use Moo;
  
  has name => (
    is       => 'rw',
    required => 1,
  );
  
  has type => (
    is       => 'rw',
    required => 1,
  );

}

1;
