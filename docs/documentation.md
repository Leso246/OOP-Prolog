### DEF-CLASS

Allows defining a new class.

**Cases where Prolog fails:**

1.  a class with the same name already exists
2.  a superclass is not an instantiated class
3.  a field’s type is incorrect (only for numbers)
4.  the type of a field present in a superclass is incorrect (only for numbers)

**Note:** for a description of type compatibility, see [TYPES](#types).

**Syntax:**

- `def_class ’(’ <class-name> ’,’ <parents> ’)’`
- `def_class ’(’ <class-name> ’,’ <parents> ’,’ <parts> ’)’`

where `<class-name>` is an atom (symbol), `<parents>` is a (possibly empty) list of atoms (symbols), and `<parts>` is a list of terms such as:

- `part ::= <field> | <method>`
- `field ::= field ’(’ <field-name>, <value> ’)`
- `| field ’(’ <field-name>, <value>, <type> ’)`
- `method ::= method ’(’ <method-name>, <arglist> ’,’ <form> ’)’`

To get all fields of a class: `get_class_fields(ClassName, Fields)`.

To get all methods of a class: `get_class_methods(ClassName, Methods)`.

**Successful examples:**

- `def_class(person, []). TRUE`
- `def_class(student, [person], [field(age, 42, integer), field(name, 'Eva'), method(talk, [], (write('My name is '), field(this, name, N), writeln(N), writeln('and I study at Bicocca')))]). TRUE`

**Failure examples:**

1.  `def_class(person, []). TRUE`  
    `def_class(person, []). FALSE`
2.  `def_class(person, [human]). FALSE`
3.  `def_class(student, [], [field(age, 42.2, integer)]). FALSE`
4.  `def_class(person, [], [field(age, 42, integer)]). TRUE`  
    `def_class(student, [person], [field(age, 45.5, float)]). FALSE`

---

### MAKE

Allows defining a new instance.

**Cases where Prolog fails:**

1.  the specified class is not instantiated
2.  the type of an inherited field value from the class or superclasses is incorrect (only for numbers)

**Note:** for a description of type compatibility, see [TYPES](#types).

**Successful examples:**

- `def_class(person, [], [field(age, 42, integer)]). TRUE`
- `make(p1, person, [age = 50]). TRUE`

**Failure examples:**

1.  `make(a, animal). FALSE`
2.  `def_class(student, [], [field(age, 42, integer)]). TRUE`  
    `make(s1, student [age = 42.2]). FALSE`

---

### INSTANCE REDEFINITION

When executing `make`, the corresponding instance is created in the knowledge base.

**Example:**

- `def_class(person, [], [field(age, 42, integer)]). TRUE`
- `make(p1, person, [age = 50]). TRUE`
- `inst(p1, X).`
- `X = [person, [age=50]].`
- `is_instance([person, [age = 50]]). TRUE`

If you redefine the instance:

- `make(p1, person, [name = 'Luca']).`

The old instance will still exist in the knowledge base, but `p1` will now be associated with the new instance.

- `inst(p1, X).`
- `X = [person, [name='Luca', age=42]].`
- `is_instance([person, [age = 50]]). TRUE`
- `is_instance([person, [name='Luca', age=42]]). TRUE`

**Note:**  
If you define another class:

- `def_class(animal, [], [field(legs, 4)]). TRUE`

and then redefine the instance `p1`:

- `make(p1, animal). TRUE`

Now `p1` is associated only with the `animal` instance.

- `inst(p1, X).`
- `X = [animal, [legs=4]].`

The name is associated with a single instance even if of different classes. This behavior avoids issues when retrieving fields and invoking methods if they share the same name in two classes.

---

### IS_CLASS

Succeeds if the atom passed is a class name. Syntax:

- `is_class ’(’ <class-name> ’)`

**Successful examples:**

- `def_class(person, []). TRUE`
- `is_class(person). TRUE`

**Failure examples:**

- `is_class(animal). FALSE`

---

### IS_INSTANCE

Succeeds if the object passed is an instance of a class. Syntax:

- `is_instance ’(’ <value> ’)`
- `is_instance ’(’ <value> ’,’ <class-name> ’)`

`is_instance/1` succeeds if `<value>` is any instance.  
`is_instance/2` succeeds if `<value>` is an instance of a class having `<class-name>` as a superclass.

**Successful examples:**

1.  `def_class(person, []). TRUE`  
    `make(p1, person). TRUE`  
    `is_instance([person, []]). TRUE`
2.  `def_class(person, []). TRUE`  
    `def_class(student, [person]). TRUE`  
    `make(p1, student). TRUE`  
    `inst(p1, X), is_instance(X, person). TRUE`

**Note:** a class is not a superclass of itself, so `is_instance([student, []], student).` returns `FALSE`.

---

### INST

Retrieves an instance by the name given to `make`.

**Successful examples:**

- `def_class(person, [], [field(age, 50), field(name, 'Eva')]). TRUE`
- `make(p1, person, [age = 42]). TRUE`
- `inst(p1, Instance).`
- `Instance = [person, [age=42, name='Eva']].`

---

### FIELD

Extracts a field value from a class. Syntax:

- `field ’(’ <instance> ’,’ <field-name> ’,’ <result> ’)`

**Successful examples:**

- `def_class(person, [], [field(age, 50), field(name, 'Eva')]). TRUE`
- `make(p1, person, [age = 42]). TRUE`
- `inst(p1, X), field(X, age, Value).`
- `Value = 42.`

---

### FIELDX

Extracts a value by traversing a chain of attributes. Syntax:

- `fieldx ’(’ <instance> ’,’ <field-names> ’,’ <result> ’)`

**Successful examples:**

- `def_class(person, [], [field(name, "pippo", string), field(age, 18)]). TRUE`
- `def_class(student, [person], [field(name, "student", string), field(friend, nil, person)]). TRUE`
- `make(pippo, person). TRUE`
- `inst(pippo, X), make(s1, student, [name = "Gianfranco", friend = X]). TRUE`
- `inst(s1, X), make(pluto, student, [classmate = X]). TRUE`
- `inst(pluto, X), fieldx(X, [classmate, friend], Friend).`
- `Friend = [person, [age=18, name="pippo"]].`

---

### METHODS

If a method with that name exists in the instance class or its superclasses, it is invoked.

**Note:** methods can be overloaded regarding the number of arguments.

**Successful examples:**

1.  `def_class(person, [], [field(name, 'Eva'), method(talk, [], (write('My name is '), field(this, name, N), writeln(N), writeln('and I study at Bicocca.'))), method(to_string, [ResultString], (with_output_to(string(ResultString), (field(this, name, N), field(this, university, U), format('#<~w Student ~w>', [U, N])))), field(university, "UNIMIB")]).`  
    `make(p1, person). TRUE`  
    `inst(p1, X), talk(X).`  
    `My name is Eva`  
    `and I study at Bicocca`  
    `true.`  
    `inst(p1, X), to_string(X, S).`  
    `S = "#<UNIMIB Student Eva>".`
2.  Assuming the class "person" is already defined:  
    `def_class(student, [person], [method(talk, [Food], (write('I am eating '), writeln(Food), write('for lunch')))]). TRUE`  
    `make(s1, student). TRUE`  
    `inst(s1, X), talk(X, pasta).`  
    `I am eating pasta`  
    `for lunch`  
    `true.`

**Failure example:**

- `inst(p1, X), eat(X). FALSE`

---

### TYPES

Type checking is implemented only for numeric fields. The three considered types are `float`, `rational`, and `integer`. Prolog logic is followed: each type is compatible with itself, an integer can be placed in a rational but not the reverse, an integer cannot be placed in a float, and all other combinations return `false`.

If a superclass has a field without type ("undefined"), subclasses using `make` can assign any desired type, but not vice versa.

**Successful examples:**

- `def_class(person, [], [field(age, 50)]). TRUE`
- `def_class(student, [person], [field(age, 'sixteen')]). TRUE`
- `make(p1, person, [age = 17.5]). TRUE`

**Failure examples:**

- `def_class(person, [], [field(age, 50, integer)]). TRUE`
- `make(p1, person, [age = 'twenty']). FALSE`
- `make(p1, person, [age = 42.2]). FALSE`
- `def_class(student, [person], [field(age, 42.2)]). FALSE`
- `def_class(student, [person], [field(age, 42)]). TRUE`
- `make(s1, student, [age = 'twentyfive']). FALSE`
