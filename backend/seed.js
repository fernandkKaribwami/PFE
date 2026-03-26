const mongoose = require('mongoose');
const Faculty = require('./models/Faculty');

const USMBA_FACULTIES = [
  { 
    name: 'Faculté des Sciences Dhar El Mahraz – Fès', 
    slug: 'sciences-dhar-el-mahraz',
    location: 'Fès',
    description: 'Faculté des Sciences Dhar El Mahraz - Université Sidi Mohamed Ben Abdellah'
  },
  { 
    name: 'Faculté des Lettres et Sciences Humaines Saïs – Fès', 
    slug: 'lettres-sciences-humaines-sais',
    location: 'Fès',
    description: 'Faculté des Lettres et Sciences Humaines Saïs'
  },
  { 
    name: 'Faculté des Sciences Juridiques, Économiques et Sociales – Fès', 
    slug: 'sjecs',
    location: 'Fès',
    description: 'Faculté des Sciences Juridiques, Économiques et Sociales'
  },
  { 
    name: 'Faculté de Médecine et de Pharmacie – Fès', 
    slug: 'medecine-pharmacie',
    location: 'Fès',
    description: 'Faculté de Médecine et de Pharmacie'
  },
  { 
    name: 'École Nationale des Sciences Appliquées (ENSA) – Fès', 
    slug: 'ensa-fes',
    location: 'Fès',
    description: 'École Nationale des Sciences Appliquées - Fès'
  },
  { 
    name: 'École Nationale des Sciences Appliquées (ENSA) – Taza', 
    slug: 'ensa-taza',
    location: 'Taza',
    description: 'École Nationale des Sciences Appliquées - Taza'
  },
  { 
    name: 'École Supérieure de Technologie (EST) – Fès', 
    slug: 'est-fes',
    location: 'Fès',
    description: 'École Supérieure de Technologie'
  },
  { 
    name: 'Faculté Polydisciplinaire – Taza', 
    slug: 'fspt-taza',
    location: 'Taza',
    description: 'Faculté Polydisciplinaire de Taza'
  },
  { 
    name: 'École Supérieure d\'Éducation et de Formation – Fès', 
    slug: 'esef',
    location: 'Fès',
    description: 'École Supérieure d\'Éducation et de Formation'
  },
  { 
    name: 'Institut des Sciences du Sport', 
    slug: 'inst-sciences-sport',
    location: 'Fès',
    description: 'Institut des Sciences du Sport'
  },
  { 
    name: 'Centres de recherche et doctorat', 
    slug: 'centres-recherche',
    location: 'Fès',
    description: 'Centres de recherche et programmes doctoraux'
  }
];

// Liste des noms des facultés
const FACULTY_NAMES = USMBA_FACULTIES.map(faculty => faculty.name);

console.log('Liste des noms des facultés :', FACULTY_NAMES);

async function seedFaculties() {
  try {
    await mongoose.connect('mongodb+srv://admin:1234@cluster0.ujlt08n.mongodb.net/usmba_db?retryWrites=true&w=majority&appName=Cluster0');
    console.log('📦 Connected to MongoDB');

    const count = await Faculty.countDocuments();
    if (count > 0) {
      console.log(`✅ Faculties already seeded (${count} faculties found)`);
      await mongoose.disconnect();
      return;
    }

    const result = await Faculty.insertMany(USMBA_FACULTIES);
    console.log(`✅ Successfully seeded ${result.length} faculties`);
    result.forEach(faculty => {
      console.log(`   - ${faculty.name} (ID: ${faculty._id})`);
    });
  } catch (e) {
    console.error('❌ Seed error:', e.message);
    if (e.name === 'MongoServerError' && e.code === 11000) {
      console.error('❌ Duplicate key error - faculties may already exist');
      console.log('   Attempting to clean up duplicates...');
      try {
        await Faculty.deleteMany({});
        console.log('   🗑️ Deleted all faculties');
        const result = await Faculty.insertMany(USMBA_FACULTIES);
        console.log(`✅ Successfully seeded ${result.length} faculties after cleanup`);
      } catch (cleanupError) {
        console.error('❌ Cleanup failed:', cleanupError.message);
      }
    }
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

seedFaculties();
