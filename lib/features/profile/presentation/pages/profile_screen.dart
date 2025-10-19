import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:sales_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:sales_app/features/profile/presentation/bloc/profile_state.dart';

import 'package:sales_app/features/users/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfile());
  }

  void _showEditDialog(UserModel user) {
    final firstName = TextEditingController(text: user.firstName);
    final lastName = TextEditingController(text: user.lastName);
    final email = TextEditingController(text: user.email);
    final gender = user.gender ?? 'male';

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
                TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (v) {},
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      final payload = {
                        'first_name': firstName.text.trim(),
                        'last_name': lastName.text.trim(),
                        'email': email.text.trim(),
                      };
                      context.read<ProfileBloc>().add(UpdateProfile(user.id, payload));
                      Navigator.pop(context);
                    },
                    child: const Text('Save'))
              ],
            ));
  }

  void _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Account Deletion'),
        content: Text('Your account deletion must be confirmed by an administrator. Proceed to request deletion for ${user.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Request')),
        ],
      ),
    );
    if (confirm == true) {
      context.read<ProfileBloc>().add(RequestAccountDeletion(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                CircleAvatar(radius: 36, child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')),
                const SizedBox(height: 12),
                Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(user.email),
                const SizedBox(height: 12),
                ListTile(title: const Text('Username'), subtitle: Text(user.username)),
                ListTile(title: const Text('Gender'), subtitle: Text(user.gender ?? 'N/A')),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditDialog(user),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(user),
                        icon: const Icon(Icons.delete_forever),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        label: const Text('Request Account Deletion'),
                      ),
                    ),
                  ],
                ),
              ]),
            );
          } else if (state is ProfileError) {
            return Center(child: Text(state.error));
          } else {
            return const Center(child: Text('No profile loaded'));
          }
        },
      ),
    );
  }
}