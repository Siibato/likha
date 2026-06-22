class CoreValueStatement {
  final int id;
  final String coreValue;
  final String statement;

  const CoreValueStatement({
    required this.id,
    required this.coreValue,
    required this.statement,
  });
}

const coreValueStatements = [
  CoreValueStatement(id: 1, coreValue: 'Maka-Diyos', statement: "Expresses one's spiritual beliefs while respecting the spiritual beliefs of others"),
  CoreValueStatement(id: 2, coreValue: 'Makatao', statement: 'Demonstrates pride in being a Filipino; exercises the right and responsibilities of a Filipino citizen'),
  CoreValueStatement(id: 3, coreValue: 'Maka-kalikasan', statement: 'Cares for the environment and utilizes resources wisely, judiciously, and economically'),
  CoreValueStatement(id: 4, coreValue: 'Makabansa', statement: 'Demonstrates pride in being a Filipino; exercises the rights and responsibilities of a Filipino citizen'),
  CoreValueStatement(id: 5, coreValue: 'Maka-Diyos', statement: 'Shows adherence to ethical principles by upholding truth'),
  CoreValueStatement(id: 6, coreValue: 'Makatao', statement: 'Listens attentively and speaks to communicate effectively'),
  CoreValueStatement(id: 7, coreValue: 'Maka-kalikasan', statement: 'Demonstrates resourcefulness, creativity, and innovation in dealing with everyday problems'),
  CoreValueStatement(id: 8, coreValue: 'Makabansa', statement: 'Demonstrates appropriate behavior in carrying out activities in the school, community, and country'),
];

const coreValueNames = ['Maka-Diyos', 'Makatao', 'Maka-kalikasan', 'Makabansa'];

const coreValueMarkings = ['AO', 'SO', 'NO', 'RO'];

List<CoreValueStatement> statementsForCoreValue(String name) {
  return coreValueStatements.where((s) => s.coreValue == name).toList();
}
