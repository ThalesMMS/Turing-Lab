part of 'help_page.dart';

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  );
}

Widget _buildCard({
  required String title,
  String? description,
  Widget? leading,
  Widget? trailing,
  Widget? subtitle,
  Color? backgroundColor,
  bool expandable = false,
  Widget? expandedChild,
}) {
  if (expandable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: backgroundColor,
      child: ExpansionTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle ?? (description == null ? null : Text(description)),
        trailing: trailing,
        children: [
          if (expandedChild != null)
            expandedChild
          else if (description != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description),
            ),
        ],
      ),
    );
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 8.0),
    color: backgroundColor,
    child: ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle ?? (description == null ? null : Text(description)),
      trailing: trailing,
    ),
  );
}
