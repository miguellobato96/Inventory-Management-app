import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ChangeUserDialog extends StatelessWidget {
  final List<UserModel> users;
  final void Function(UserModel) onUserSelected;

  const ChangeUserDialog({
    super.key,
    required this.users,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select User"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.username),
              subtitle: Text(user.email),
              onTap: () => onUserSelected(user),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
