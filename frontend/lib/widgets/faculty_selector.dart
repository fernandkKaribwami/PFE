import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/faculty_provider.dart';
import '../theme/app_colors.dart';

class FacultySelector extends StatelessWidget {
  final Function(String?)? onFacultyChanged;

  const FacultySelector({super.key, this.onFacultyChanged});

  @override
  Widget build(BuildContext context) {
    return Consumer<FacultyProvider>(
      builder: (context, facultyProvider, child) {
        // Load faculties if not already loaded
        if (facultyProvider.faculties.isEmpty && !facultyProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            facultyProvider.loadFaculties();
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            color: Theme.of(context).cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: facultyProvider.selectedFacultyId,
                hint: Row(
                  children: const [
                    Icon(Icons.school, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sélectionner une faculté',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                items: facultyProvider.faculties.map<DropdownMenuItem<String>>((
                  faculty,
                ) {
                  return DropdownMenuItem<String>(
                    value: faculty['_id']?.toString(),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.school,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            faculty['name']?.toString() ?? 'Faculté inconnue',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (faculty['membersCount'] != null)
                          Text(
                            '(${faculty['membersCount']} membres)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  facultyProvider.selectFaculty(value);
                  onFacultyChanged?.call(value);
                },
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
