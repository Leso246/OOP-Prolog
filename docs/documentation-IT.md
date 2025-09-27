### DEF-CLASS

Permette di definire una nuova classe.

**Casi in cui Prolog fallisce:**

1.  esiste già una classe con lo stesso nome
2.  una superclasse non è una classe istanziata
3.  il tipo di un field è errato (solo per i numeri)
4.  il tipo di un field che è presente in una superclasse è errato (solo per i numeri)

**Nota**: per la spiegazione della compatibilità tra i tipi, andare nella sezione [TIPI](#tipi).

**La sua sintassi è:**

- `def_class ’(’ <class-name> ’,’ <parents> ’)’`
- `def_class ’(’ <class-name> ’,’ <parents> ’,’ <parts> ’)’`

dove `<class-name>` è un atomo (simbolo) e `<parents>` è una lista (possibilmente vuota) di atomi (simboli), e `<parts>` è una lista di termini siffatti:

- `part ::= <field> | <method>`
- `field ::= field ’(’ <field-name>, <value> ’)`
- `| field ’(’ <field-name>, <value>, <type> ’)`
- `method ::= method ’(’ <method-name>, <arglist> ’,’ <form> ’)’`

Per ottenere tutti i fields di una classe si può usare: `get_class_fields(ClassName, Fields)`.

Per ottenere tutti i metodi di una classe si può usare: `get_class_methods(ClassName, Methods)`.

**Esempi di successo:**

- `def_class(persona, []). TRUE`
- `def_class(studente, [persona], [field(age, 42, integer), field(name, 'Eva'), method(talk, [], (write('Mi chiamo '), field(this, name, N), writeln(N), writeln('e studio alla bicocca')))]). TRUE`

**Esempi di fallimento:**

1.  `def_class(persona, []). TRUE`
    `def_class(persona, []). FALSE`
2.  `def_class(persona, [essereUmano]). FALSE`
3.  `def_class(studente, [], [field(age, 42.2, integer)]). FALSE`
4.  `def_class(persona, [], [field(age, 42, integer)]). TRUE`
    `def_class(studente, [persona], [field(age, 45.5, float)]). FALSE`

---

### MAKE

Permette di definire una nuova istanza.

**Casi in cui Prolog fallisce:**

1.  la classe specificata non è una classe istanziata
2.  il tipo del valore di un field ereditato dalla classe o dalle superclassi è errato (solo per i numeri)

**Nota**: per la spiegazione della compatibilità tra i tipi, andare nella sezione[TIPI](#tipi).

**Esempi di successo:**

- `def_class(persona, [], [field(age, 42, integer)]). TRUE`
- `make(p1, persona, [age = 50]). TRUE`

**Esempi di fallimento:**

1.  `make(a, animale). FALSE`
2.  `def_class(studente, [], [field(age, 42, integer)]). TRUE`
    `make(s1, studente [age = 42.2]). FALSE`

---

### RIDEFINIZIONE DI ISTANZE

Quando si esegue una make, viene creata l'istanza corrispondente nella base di conoscenza.

**Esempio:**

- `def_class(persona, [], [field(age, 42, integer)]). TRUE`
- `make(p1, persona, [age = 50]). TRUE`
- `inst(p1, X).`
- `X = [persona, [age=50]].`
- `is_instance([persona, [age = 50]]). TRUE`

Provando a ridefinire l'istanza:

- `make(p1, persona, [nome = 'Luca']).`

La vecchia istanza esisterà ancora nella base di conoscenza, ma a p1 verrà associata la nuova istanza.

- `inst(p1, X).`
- `X = [persona, [nome='Luca', age=42]].`
- `is_instance([persona, [age = 50]]). TRUE`
- `is_instance([persona, [nome='Luca', age=42]]). TRUE`

**Nota:**
Nel caso in cui si vada a definire un'altra classe:

- `def_class(animale, [], [field(zampe, 4)]). TRUE`

e poi si ridefinisca l'istanza p1

- `make(p1, animale). TRUE`

Ora l'istanza p1 è associata solo all'istanza della classe animale.

- `inst(p1, X).`
- `X = [animale, [zampe=4]].`

Il nome sarà associato a un'unica istanza anche se di classi diverse. Questo comportamento è stato scelto per evitare problemi nel recupero dei field e nell'invocazione dei metodi nel caso in cui abbiano lo stesso nome nelle due classi.

---

### IS_CLASS

Ha successo se l’atomo passatogli è il nome di una classe. La sintassi è:

- `is_class ’(’ <class-name> ’)`

**Esempi di successo:**

- `def_class(persona, []). TRUE`
- `is_class(persona). TRUE`

**Esempi di fallimento:**

- `is_class(animale). FALSE`

---

### IS_INSTANCE

Ha successo se l’oggetto passatogli è l’istanza di una classe. La sintassi è:

- `is_instance ’(’ <value> ’)`
- `is_instance ’(’ <value> ’,’ <class-name> ’)`

`is_instance/1` ha successo se `<value>` è un’istanza qualunque.

`is_instance/2` ha successo se `<value>` è un’istanza di una classe che ha `<class-name>` come superclasse.

**Esempi di successo:**

1.  `def_class(persona, []). TRUE`
    `make(p1, persona). TRUE`
    `is_instance([persona, []]). TRUE`
2.  `def_class(persona, []). TRUE`
    `def_class(studente, [persona]). TRUE`
    `make(p1, studente). TRUE`
    `inst(p1, X), is_instance(X, persona). TRUE`

**Nota:** una classe non è superclasse di sé stessa, quindi la query `is_instance([studente, []], studente).` darà `FALSE`.

---

### INST

Recupera un’istanza dato il nome con cui è stata creata da make.

**Esempi di successo:**

- `def_class(persona, [], [field(age, 50), field(name, 'Eva')]). TRUE`
- `make(p1, persona, [age = 42]). TRUE`
- `inst(p1, Instance).`
- `Instance = [persona, [age=42, name='Eva']].`

---

### FIELD

Estrae il valore di un campo da una classe. La sintassi è:

- `field ’(’ <instance> ’,’ <field-name> ’,’ <result> ’)`

**Esempi di successo:**

- `def_class(persona, [], [field(age, 50), field(name, 'Eva')]). TRUE`
- `make(p1, persona, [age = 42]). TRUE`
- `inst(p1, X), field(X, age, Value).`
- `Value = 42.`

---

### FIELDX

Estrae il valore da una classe percorrendo una catena di attributi. La sintassi è:

- `fieldx ’(’ <instance> ’,’ <field-names> ’,’ <result> ’)`

**Esempi di successo:**

- `def_class(person, [], [field(name, "pippo", string), field(age, 18)]). TRUE`
- `def_class(student, [person], [field(name, "student", string), field(amico, nil, person)]). TRUE`
- `make(pippo, person). TRUE`
- `inst(pippo, X), make(s1, student, [name = "Gianfranco", amico = X]). TRUE`
- `inst(s1, X), make(pluto, student, [compagno = X]). TRUE`
- `inst(pluto, X), fieldx(X, [compagno, amico], Amico).`
- `Amico = [person, [age=18, name="pippo"]].`

---

### METODI

Se nella classe dell'istanza o nelle superclassi è presente un metodo con quel nome, esso viene invocato.

**Nota:** è possibile fare un 'overloading' dei metodi, per quanto riguarda l'arità degli argomenti.

**Esempi di successo:**

1.  `def_class(persona, [], [field(name, 'Eva'), method(talk, [], (write('Mi chiamo '), field(this, name, N), writeln(N), writeln('e studio alla Bicocca.'))), method(to_string, [ResultingString], (with_output_to(string(ResultingString), (field(this, name, N), field(this, university, U), format('#<~w Student ~w>', [U, N])))), field(university, "UNIMIB")]).`
    `make(p1, persona). TRUE`
    `inst(p1, X), talk(X).`
    `Mi chiamo Eva`
    `e studio alla bicocca`
    `true.`
    `inst(p1, X), to_string(X, S).`
    `S = "#<UNIMIB Student Eva>".`
2.  Immaginiamo di aver già definito la classe "persona" di prima
    `def_class(studente, [persona], [method(talk, [Cibo], (write('Sto mangiando '), writeln(Cibo), write('per pranzo')))]). TRUE`
    `make(s1, studente). TRUE`
    `inst(s1, X), talk(X, pasta).`
    `Sto mangiando pasta`
    `per pranzo`
    `true.`

**Esempi di fallimento:**

- `inst(p1, X), mangia(X). FALSE`

---

### TIPI

È stato implementato un controllo dei tipi dei field, solo per quelli numerici. I tre tipi presi in considerazione sono `float`, `rational` e `integer`. È stata seguita la logica di Prolog: ogni tipo è ovviamente compatibile con sé stesso, inoltre si può mettere un integer in un rational ma non il contrario, NON si può mettere un integer in un float, tutte le altre combinazioni restituiranno `false`.

Se in una superclasse abbiamo un field senza tipo, considerato "undefined", nelle sottoclassi e utilizzando make possiamo mettere il tipo da noi desiderato, NON vale il contrario.

**Esempi di successo:**

- `def_class(persona, [], [field(age, 50)]). TRUE`
- `def_class(studente, [persona], [field(age, 'sedici')]). TRUE`
- `make(p1, persona, [age = 17.5]). TRUE`

**Esempi di fallimento:**

- `def_class(persona, [], [field(age, 50, integer)]). TRUE`
- `make(p1, persona, [age = 'venti']). FALSE`
- `make(p1, persona, [age = 42.2]). FALSE`
- `def_class(studente, [persona], [field(age, 42.2)]). FALSE`
- `def_class(studente, [persona], [field(age, 42)]). TRUE`
- `make(s1, studente, [age = 'venticinque']). FALSE`
