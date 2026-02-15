const mongoose = require('mongoose');
const Faculty = require('./models/Faculty');

const USMBA_FACULTIES = [
  { name: 'Faculté des Sciences Dhar El Mahraz – Fès', slug: 'sciences-dhar-el-mahraz' },
  { name: 'Faculté des Lettres et Sciences Humaines Saïs – Fès', slug: 'lettres-sciences-humaines-sais' },
  { name: 'Faculté des Sciences Juridiques, Économiques et Sociales – Fès', slug: 'sjecs' },
  { name: 'Faculté de Médecine et de Pharmacie – Fès', slug: 'medecine-pharmacie' },
  { name: 'École Nationale des Sciences Appliquées (ENSA) – Fès', slug: 'ensa-fes' },
  { name: 'École Nationale des Sciences Appliquées (ENSA) – Taza', slug: 'ensa-taza' },
  { name: 'École Supérieure de Technologie (EST) – Fès', slug: 'est-fes' },
  { name: 'Faculté Polydisciplinaire – Taza', slug: 'fstt-taza' },
  { name: 'École Supérieure d\'Éducation et de Formation – Fès', slug: 'esef' },
  { name: 'Institut des Sciences du Sport', slug: 'inst-sciences-sport' },
  { name: 'Centres de recherche et doctorat', slug: 'centres-recherche' }
];

async function seedFaculties() {
  try {
    await mongoose.connect('mongodb://127.0.0.1:27017/usmba_social');
    console.log('📦 Connected to MongoDB');

    const count = await Faculty.countDocuments();
    if (count > 0) {
      console.log('✅ Faculties already seeded');
      return;
    }

    await Faculty.insertMany(USMBA_FACULTIES);
    console.log(`✅ Seeded ${USMBA_FACULTIES.length} faculties`);
  } catch (e) {
    console.error('❌ Seed error:', e.message);
  } finally {
    await mongoose.disconnect();
  }
}

seedFaculties();
