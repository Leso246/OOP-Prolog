%%%% Simone Lesinigo https://github.com/Leso246

%%% -*- Mode: Prolog -*-

%%% oop.pl

% Define a class without parts
def_class(ClassName, Parents) :-
    def_class(ClassName, Parents, []),
    !.

% Define a class 
def_class(ClassName, Parents, Parts) :-
    \+ is_class(ClassName),
    are_classes_list(Parents),
    check_part_type_compatibility(Parts, Parents),
    assertz(class(ClassName, Parents)),
    assert_parts(ClassName, Parts),
    !.

% Check if all parents are instantiated classes
are_classes_list([]).

are_classes_list([Parent | Rest]) :-
    is_class(Parent),
    are_classes_list(Rest).

% Helper to assert the parts of a class
assert_parts(_, []).
assert_parts(ClassName, [Part | Rest]) :-
    assert_part(ClassName, Part),
    assert_parts(ClassName, Rest).

% Assert a field or a method to a class
assert_part(ClassName, field(FieldName, Value)) :-
    assertz(field_value_in_class(ClassName, FieldName, Value)), 
    !.

assert_part(ClassName, field(_, Value, Type)) :-
    \+ check_value_type_compatibility(Value, Type),  
    !,
    retractall(class(ClassName, _)),
    retractall(field_value_in_class(ClassName, _, _)),
    retractall(field_value_in_class(ClassName, _, _, _)),
    retractall(method_in_class(ClassName, _, _, _)),
    fail.

assert_part(ClassName, field(FieldName, Value, Type)) :-
    assertz(field_value_in_class(ClassName, 
                                 FieldName, 
                                 Value, 
                                 Type)),
    !.

assert_part(ClassName, method(MethodName, ArgList, Form)) :-
    assertz(method_in_class(ClassName, 
                            MethodName, 
                            ArgList, 
                            Form)),
    define_method(MethodName, ArgList), 
    !.

% Check that the type of a field while defining
% a class is correct (only for numbers)
check_value_type_compatibility(Value, integer) :-
    !,
    integer(Value).

check_value_type_compatibility(Value, float) :-
    !,
    float(Value).

check_value_type_compatibility(Value, rational) :-
    !,
    rational(Value).

check_value_type_compatibility(_, _).

% Version of make/2 that calls make/3
make(InstanceName, ClassName) :-
    make(InstanceName, ClassName, []).

% Version of make/3 that create a new instance of a class
% InstanceName is an atom
% Istance is not already defined
make(InstanceName, ClassName, FieldValues) :-
    atom(InstanceName),
    \+ already_existing_instance(InstanceName),
    is_class(ClassName),
    validate_field_values(ClassName, FieldValues),
    inherit_fields(InstanceName, ClassName, FieldValues),
    !.

% InstanceName is an atom
% Istance is already defined
make(InstanceName, ClassName, FieldValues) :-
    atom(InstanceName),
    already_existing_instance(InstanceName),
    retractall(inst(InstanceName, [_, _])),
    is_class(ClassName),
    validate_field_values(ClassName, FieldValues),
    inherit_fields(InstanceName, ClassName, FieldValues),
    !.

% InstanceName is a var
make(InstanceName, ClassName, FieldValues) :-
    var(InstanceName),
    is_class(ClassName),
    validate_field_values(ClassName, FieldValues),
    get_class_fields(ClassName, ClassFieldValues),
    find_all_superclass_fields(ClassName, SuperclassFields),
    append(ClassFieldValues, SuperclassFields, InstanceFields),
    transform_fields(InstanceFields, TransformedClassFieldValues),
    append(FieldValues, TransformedClassFieldValues, AllFields),
    exclude_existing_fields(AllFields, Finals),
    InstanceName = [ClassName, Finals],
    !.

% InstanceName is anything else
make(InstanceName, ClassName, FieldValues) :-
    is_class(ClassName),
    validate_field_values(ClassName, FieldValues),
    get_class_fields(ClassName, ClassFieldValues),
    find_all_superclass_fields(ClassName, SuperclassFields),
    append(ClassFieldValues, SuperclassFields, InstanceFields),
    transform_fields(InstanceFields, TransformedClassFieldValues),
    append(FieldValues, TransformedClassFieldValues, AllFields),
    exclude_existing_fields(AllFields, Finals),
    NewInstance = [ClassName, Finals],
    InstanceName = NewInstance,
    !.

% Check if an instance with that name already exists
already_existing_instance(InstanceName) :-
    inst(InstanceName, Instance),
    is_instance(Instance).

% Assert the fields of the class into the instance
inherit_fields(InstanceName, ClassName, FieldValues) :-
    get_class_fields(ClassName, ClassFields),
    find_all_superclass_fields(ClassName, SuperclassFields),
    append(ClassFields, SuperclassFields,  AllClassesFields),
    transform_fields(AllClassesFields, TransformedFields),
    append(FieldValues, TransformedFields, AllFields),
    exclude_existing_fields(AllFields, FieldsToInherit),
    assertz(is_instance([ClassName, FieldsToInherit])),
    assertz(inst(InstanceName, [ClassName, FieldsToInherit])).

% Check if Instance is a defined istance
% which superclass is ClassName
is_instance(Instance, ClassName) :-
    inst(_, Instance),
    get_instance_class(Instance, InstanceClass),
    all_superclass_of_a_class(InstanceClass, SuperClasses),
    member(ClassName, SuperClasses),
    !.

% Get all the superclasses of a class
all_superclass_of_a_class(ClassName, SuperClasses) :-
    all_superclass_of_a_class_recursive([ClassName], 
                                        [], 
                                        SuperClassesWithDuplicates),
    list_to_set(SuperClassesWithDuplicates, SuperClasses).

all_superclass_of_a_class_recursive([], _, []).

all_superclass_of_a_class_recursive([Class | Rest], 
                                    Visited, 
                                    SuperClasses) :-
    % Verifiy if the class was already visited
    member(Class, Visited),
    !,
    all_superclass_of_a_class_recursive(Rest, Visited, SuperClasses).

% Add the current class to the superclasses (if not already present)
all_superclass_of_a_class_recursive([Class | Rest], 
                                    Visited, 
                                    SuperClasses) :-
    append(Visited, [Class], UpdatedVisited),
    superclass(Class, ClassSuperClasses),
    append(Rest, ClassSuperClasses, NewQueue),
    all_superclass_of_a_class_recursive(NewQueue, 
                                        UpdatedVisited, 
                                        RecursiveSuperClasses),
    append(ClassSuperClasses, RecursiveSuperClasses, SuperClasses).

% Find all fields of the superclass and its superclasses
find_all_superclass_fields(ClassName, Fields) :-
    superclass(ClassName, Parents),
    find_superclass_fields(Parents, [], Fields).

% Recursive helper to find superclass fields
find_superclass_fields([], Fields, Fields).

find_superclass_fields([Parent | Rest], Acc, Fields) :-
    get_class_fields(Parent, ParentFields),
    append(Acc, ParentFields, NewAcc),
    find_all_superclass_fields(Parent, SuperSuperFields),
    append(NewAcc, SuperSuperFields, CombinedFields),
    find_superclass_fields(Rest, CombinedFields, Fields).

% Get all class methods
get_class_methods(ClassName, Methods) :-
    catch(findall(method(MethodName, ArgList, Form), 
                  method_in_class(ClassName, 
                                  MethodName, 
                                  ArgList, 
                                  Form), 
                  Methods),
          _,
          Methods = []).

%  Declare predicates as dynamic
:- dynamic field_value_in_class/3.
:- dynamic field_value_in_class/4.
:- dynamic instance/2.
:- dynamic is_instance/1.
:- dynamic is_instance/2.
:- dynamic inst/2.

% Get all the fields of a class
get_class_fields(ClassName, Fields) :-
    catch(findall(field(FieldName, DefaultValue), 
                  field_value_in_class(ClassName, 
                                       FieldName, 
                                       DefaultValue), 
                  FieldsWithoutType),
          _,
          FieldsWithoutType = []),
    catch(get_class_fields_with_type(ClassName, FieldsWithType),
          _,
          FieldsWithType = []),
    append(FieldsWithoutType, FieldsWithType, Fields).

% Get all the fields of a class - Fields with type
get_class_fields_with_type(ClassName, Fields) :-
    findall(field(FieldName, DefaultValue, Type), 
            field_value_in_class(ClassName, 
                                 FieldName, 
                                 DefaultValue, 
                                 Type), 
            Fields).

% Fallback clause for field_value_in_class/4
field_value_in_class(_, _, _, _) :- fail.

% Transform fields of a class in fields of an instance
transform_fields([], []).

transform_fields([field(Name, Value) | Rest], 
                 [Name = Value | TransformedRest]) :-
    transform_fields(Rest, TransformedRest).

transform_fields([field(Name, Value, _Type) | Rest], 
                 [Name = Value | TransformedRest]) :-
    transform_fields(Rest, TransformedRest).

% Exclude the fields that are already defined
exclude_existing_fields(InputList, OutputList) :-
    exclude_duplicates(InputList, [], OutputList),
    !.

% Helper to exlcude fields
exclude_duplicates([], _, []).

exclude_duplicates([Name = Value | T], Seen, [Name = Value | R]) :-
    \+ member(Name = _, Seen),
    exclude_duplicates(T, [Name = Value | Seen], R).

exclude_duplicates([Name = _ | T], Seen, R) :-
    member(Name = _, Seen),
    exclude_duplicates(T, Seen, R).

% Check if a given symbol is the name of a defined class
is_class(ClassName) :-
    current_predicate(class/2),
    class(ClassName, _).

% Retrieves the value of a field from an instance of a class
field([_, Fields], Name, Value) :- 
    member(Name = Value, Fields),
    !.

% Recursive research 
fieldx(InstanceName, [FieldName], Result) :-
    field(InstanceName, FieldName, Result),
    !.

fieldx(InstanceName, [FieldName | RestFieldNames], Result) :-
    field(InstanceName, FieldName, NextInstance),
    !,
    fieldx(NextInstance, RestFieldNames, Result).

% Class of an instance
instance_of(InstanceName, ClassName) :-
    instance(InstanceName, ClassName).

% Superclass of a class
superclass(ClassName, Parents) :-
    is_class(ClassName),
    class(ClassName, Parents).

% Invoke a method on an
% instance with arguments.
invoke(Instance, MethodName, Args) :-
    get_instance_class(Instance, ClassName),
    find_method(ClassName, MethodName, Args, MethodBody),
    replace_this(MethodBody, Instance, NewBody),
    call(NewBody).

% Retrieves the class of an undefined 
get_instance_class([ClassName, _], ClassName).

% Replace this in a body of a method
replace_this(Term, ReplaceWith, NewTerm) :-
    replace_this_helper(Term, ReplaceWith, NewTerm), 
    !.

replace_this_helper(Term, ReplaceWith, NewTerm) :-
    compound(Term),
    !,
    Term =.. [F | Args],
    replace_this_args(Args, ReplaceWith, NewArgs),
    NewTerm =.. [F | NewArgs].

replace_this_helper(This, ReplaceWith, ReplaceWith) :-
    This == this.

replace_this_helper(Atom, _, Atom).

replace_this_args([], _, []).

replace_this_args([Arg | RestArgs], 
                  ReplaceWith, 
                  [NewArg | NewRestArgs]) :-  
    replace_this_helper(Arg, ReplaceWith, NewArg),
    replace_this_args(RestArgs, ReplaceWith, NewRestArgs).

% Find a method in a class or in superclasses
find_method(ClassName, MethodName, ArgList, Method) :-
    % Search the method in the current class
    method_in_class(ClassName, MethodName, ArgList, Method),
    !.

% Find the method in the superclasses
find_method(ClassName, MethodName, ArgList, Method) :-
    % Find the superclasses of the current class
    superclass(ClassName, Parents),
    
    % Search the method in the superclasses
    find_method_in_parents(Parents, MethodName, ArgList, Method).

% Search the method in the superclasses
find_method_in_parents([], _, _, _) :- fail.
find_method_in_parents([Parent | _], MethodName, ArgList, Method) :-
    find_method(Parent, MethodName, ArgList, Method),
    !.

% If the method was not found, search in the other superclasses
find_method_in_parents([_ | Rest], MethodName, ArgList, Method) :-
    find_method_in_parents(Rest, MethodName, ArgList, Method).

% Define a method with no arguments
define_method(MethodName, []) :-
    Arity is 1,
    current_predicate(MethodName/Arity),
    remove_method(MethodName, Arity),
    assert_no_arg_method(MethodName).

define_method(MethodName, []) :-
    Arity is 1,
    \+ current_predicate(MethodName/Arity),
    assert_no_arg_method(MethodName).

% Define a method with arguments
define_method(MethodName, ArgList) :-
    length(ArgList, Arity),
    TotalArity is Arity + 1,
    current_predicate(MethodName/TotalArity),
    remove_method(MethodName, TotalArity),
    assert_arg_method(MethodName, ArgList).

define_method(MethodName, ArgList) :-
    length(ArgList, Arity),
    TotalArity is Arity + 1,
    \+ current_predicate(MethodName/TotalArity),
    assert_arg_method(MethodName, ArgList).

% Helper to assert a method with arguments
assert_arg_method(MethodName, ArgList) :-
    DynamicMethod =.. [MethodName, InstanceName | ArgList],
    assertz((DynamicMethod :- 
                 invoke(InstanceName, 
                        MethodName, 
                        ArgList), 
                 !)).

% Helper to assert a method with no arguments
assert_no_arg_method(MethodName) :-
    DynamicMethod =.. [MethodName, InstanceName],
    assertz((DynamicMethod :- 
                 invoke(InstanceName, 
                        MethodName, 
                        []), 
                 !)).


remove_method(MethodName, 1) :-
    % Check if the arity is 1
    Predicate =.. [MethodName, _],
    retractall(Predicate).

remove_method(MethodName, Arity) :-
    % Check if arity is greater than 1
    Arity > 1,
    % Construct the predicate term with the specified arity
    length(Args, Arity),
    Predicate =.. [MethodName | Args],
    retractall(Predicate).


% Predicate for the validation of field types using "Make" 
% Working only for numbers
validate_field_values(_, []).

validate_field_values(ClassName, [FieldName = Value | Rest]) :-
    find_field(ClassName, FieldName, _, Type), 
    !, 
    validate_field_type(Value, Type),
    validate_field_values(ClassName, Rest).

validate_field_values(ClassName, [_ | Rest]) :-
    validate_field_values(ClassName, Rest).

% Validation of the field type
validate_field_type(Value, integer) :- 
    !, 
    integer(Value).

validate_field_type(Value, float) :- 
    !, 
    float(Value).

validate_field_type(Value, rational) :- 
    !, 
    rational(Value).

% If it's not a number, validate anything
validate_field_type(_, _).

% First, look in the same class
find_field(ClassName, FieldName, _, Type) :-
    field_value_in_class(ClassName, FieldName, _, Type),
    !.

% If it's not found in the class, look in the superclasses
find_field(ClassName, FieldName, _, Type) :-
    superclass(ClassName, Parents),
    find_field_in_parents(Parents, FieldName, Type).

% Search in superclasses
find_field_in_parents([], _, _) :- fail.
find_field_in_parents([Parent | _], FieldName, Type) :-
    field_value_in_class(Parent, FieldName, _, Type),
    !.
find_field_in_parents([_ | Rest], FieldName, Type) :-
    find_field_in_parents(Rest, FieldName, Type).

% Predicate to check the type of a number
number_type(Value, integer) :-
    integer(Value),
    !.

number_type(Value, float) :-
    float(Value),
    !.

number_type(Value, rational) :-
    rational(Value),
    !.

% Check the type compatibility while 
% defining a class using def_class

% There is nothing to check
check_part_type_compatibility([], _) :- !.
check_part_type_compatibility(_, []) :- !.

% If the value of a field without type 
% is a number, check compatibility
check_part_type_compatibility([field(FieldName, Value) | Rest], 
                              ParentClasses) :- 
    number(Value),
    !,
    number_type(Value, FieldType),
    find_type_in_superclass(ParentClasses, 
                            FieldName, 
                            ParentFieldType),
    check_field_type_compatibility(FieldType, ParentFieldType),
    check_part_type_compatibility(Rest, ParentClasses).

% If it's a field without type, skip
% Value of the field it is NOT a number
check_part_type_compatibility([field(_, _) | Rest], 
                              ParentClasses) :- 
    check_part_type_compatibility(Rest, ParentClasses).

% If it's a method, skip
check_part_type_compatibility([method(_, _, _) | Rest], 
                              ParentClasses) :- 
    check_part_type_compatibility(Rest, ParentClasses).

check_part_type_compatibility([field(FieldName, _, FieldType) | Rest], 
                              ParentClasses) :-
    !,
    % Check if the field is present in the superclass's field list
    find_type_in_superclass(ParentClasses, 
                            FieldName, 
                            ParentFieldType),
    
    check_field_type_compatibility(FieldType, ParentFieldType),
    
    % Proceed with the other fields
    check_part_type_compatibility(Rest, ParentClasses).

% Check type compatibility for numbers (true)
check_field_type_compatibility(integer, integer) :- !.
check_field_type_compatibility(integer, rational) :- !.
check_field_type_compatibility(integer, undefined) :- !.
check_field_type_compatibility(float, float) :- !.
check_field_type_compatibility(float, undefined) :- !.
check_field_type_compatibility(rational, rational) :- !.
check_field_type_compatibility(rational, undefined) :- !.

% Check type compatibility for numbers (false)
check_field_type_compatibility(integer, _) :- !, fail.
check_field_type_compatibility(_, integer) :- !, fail.
check_field_type_compatibility(float, _):- !, fail.
check_field_type_compatibility(_, float) :- !, fail.
check_field_type_compatibility(rational, _) :- !, fail.
check_field_type_compatibility(_, rational) :- !, fail.

% If it's not a number, validate anything
check_field_type_compatibility(_, _) :- true.

% Find the type of a field in a superclass 
find_type_in_superclass([ParentClass | _], FieldName, undefined) :-
    get_class_fields(ParentClass, ClassFields),
    find_all_superclass_fields(ParentClass, SuperclassFields),
    append(ClassFields, SuperclassFields, AllFields),
    \+ find_field_type(AllFields, FieldName, _FieldType),
    !.

find_type_in_superclass([ParentClass | _], FieldName, FieldType) :-
    get_class_fields(ParentClass, ClassFields),
    find_all_superclass_fields(ParentClass, SuperclassFields),
    append(ClassFields, SuperclassFields, AllFields),
    find_field_type(AllFields, FieldName, FieldType),
    !.

find_type_in_superclass([_ | Rest], FieldName, ParentFieldType) :-
    find_type_in_superclass(Rest, FieldName, ParentFieldType).

% Find the type of FieldName in the list
find_field_type([field(FieldName, _, FieldType) | _], 
                FieldName, 
                FieldType) :-
    !.  

% If FieldName doesn't have a type
% it is considered type = undefined
find_field_type([field(FieldName, _) | _], FieldName, undefined) :-
    !. 

find_field_type([_ | RestFields], FieldName, FieldType) :-
    find_field_type(RestFields, FieldName, FieldType).  

%% end of file -- oop.pl