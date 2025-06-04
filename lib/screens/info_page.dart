import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 24),

            // Developer Info
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi Developer',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nama', 'Rahel Anatasya'),
                    const SizedBox(height: 8),
                    _buildInfoRow('NIM', '123220018'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Mata Kuliah',
                      'Teknologi dan Pemrograman Mobile',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Kesan Pesan
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Kesan dan Pesan',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kesan
                    Text(
                      'Kesan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mata kuliah Teknologi dan Pemrograman Mobile sangat menarik dan memberikan pengalaman berharga dalam mengembangkan aplikasi mobile. Melalui pembelajaran Flutter, saya dapat memahami konsep-konsep pengembangan aplikasi lintas platform dengan lebih baik. Proyek TPM Flora ini membantu saya menerapkan berbagai fitur seperti manajemen database, sensor integration, dan UI/UX design yang responsif.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),

                    const SizedBox(height: 16),

                    // Pesan
                    Text(
                      'Pesan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semoga mata kuliah ini terus berkembang dan dapat memberikan pembelajaran yang lebih mendalam tentang teknologi mobile terkini. Materi yang diberikan sangat relevan dengan kebutuhan industri, dan praktik pengembangan aplikasi ini sangat membantu dalam memahami siklus pengembangan software yang sesungguhnya. Terima kasih atas bimbingan dan ilmu yang telah diberikan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                '© 2024 TPM Flora - Rahel Anatasya',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
