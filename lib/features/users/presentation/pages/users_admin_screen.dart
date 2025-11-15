import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/users/models/role_permission.dart';
import 'package:sales_app/features/users/models/user_model.dart';
import 'package:sales_app/features/users/presentation/bloc/users_bloc.dart';
import 'package:sales_app/features/users/presentation/bloc/users_event.dart';
import 'package:sales_app/features/users/presentation/bloc/users_state.dart';


class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({Key? key}) : super(key: key);

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filtered = [];
  List<UserModel> _lastUsers = [];
  List<RoleModel> _lastRoles = [];
  List<PermissionModel> _lastPermissions = [];
  bool _isSearching = false;

  // 0 = Users, 1 = Permissions
  int _viewIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(LoadUsers());
    context.read<UsersBloc>().add(LoadRolesAndPermissions());

    _searchController.addListener(() {
      _applySearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String q) {
    final term = q.trim().toLowerCase();
    if (term.isEmpty) {
      setState(() => _filtered = List<UserModel>.from(_lastUsers));
      return;
    }
    setState(() {
      _filtered = _lastUsers.where((u) {
        return u.username.toLowerCase().contains(term) ||
            u.email.toLowerCase().contains(term) ||
            u.firstName.toLowerCase().contains(term) ||
            u.lastName.toLowerCase().contains(term);
      }).toList();
    });
  }

  Future<void> _showCreateRoleSheet() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Form(
                key: formKey,
                child: Column(children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a role name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          context.read<UsersBloc>().add(CreateRoleRequested(nameController.text.trim(), description: descController.text.trim()));
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role creation requested')));
    }
  }

  Future<void> _showCreatePermissionSheet() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create Permission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Form(
                key: formKey,
                child: Column(children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name (e.g., invoices.view)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a permission name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          context.read<UsersBloc>().add(CreatePermissionRequested(nameController.text.trim(), description: descController.text.trim()));
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission creation requested')));
    }
  }

  Future<void> _showCreateUserSheet(List<RoleModel> roles) async {
    final username = TextEditingController();
    final email = TextEditingController();
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    String gender = 'male';
    int? selectedRoleId;
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Create User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: Column(children: [
                TextFormField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!re.hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
                const SizedBox(height: 8),
                TextFormField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: (v) => gender = v ?? 'male',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Role (optional)'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: selectedRoleId,
                      items: [const DropdownMenuItem<int?>(value: null, child: Text('No role'))] +
                          roles.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.name))).toList(),
                      onChanged: (v) => selectedRoleId = v,
                      isExpanded: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final payload = {
                        'username': username.text.trim(),
                        'email': email.text.trim(),
                        'first_name': firstName.text.trim(),
                        'last_name': lastName.text.trim(),
                        'gender': gender,
                        'role_id': selectedRoleId,
                        'send_reset': true
                      };
                      context.read<UsersBloc>().add(CreateUserWithRoleRequested(payload));
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Create user & send invite'),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User creation requested')));
    }
  }

  Widget _buildUserCard(UserModel u, List<RoleModel> roles) {
    final initials = (u.firstName.isNotEmpty ? u.firstName[0] : '') + (u.lastName.isNotEmpty ? u.lastName[0] : '');
    final assignedRoles = u.roles.map((id) => roles.firstWhere((r) => r.id == id, orElse: () => RoleModel(id: id, name: 'Role #$id', description: null))).toList();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(initials.toUpperCase(), style: const TextStyle(color: Colors.white)),
        ),
        title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.email, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: assignedRoles.isNotEmpty
                ? assignedRoles.map((r) => Chip(label: Text(r.name), visualDensity: VisualDensity.compact)).toList()
                : [const Chip(label: Text('No roles'), visualDensity: VisualDensity.compact)],
          )
        ]),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (val) async {
            if (val == 'resend') {
              context.read<UsersBloc>().add(ResendResetRequested(u.id));
            } else if (val == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: Text('Are you sure you want to delete ${u.username}? This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) context.read<UsersBloc>().add(DeleteUserRequested(u.id));
            } else if (val == 'assign') {
              final roleId = await showDialog<int?>(
                context: context,
                builder: (ctx) {
                  int? sel = assignedRoles.isNotEmpty ? assignedRoles.first.id : null;
                  return AlertDialog(
                    title: const Text('Assign Role'),
                    content: StatefulBuilder(builder: (c, st) {
                      return DropdownButtonFormField<int>(
                        value: sel,
                        items: roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                        onChanged: (v) {
                          sel = v;
                          st(() {});
                        },
                        decoration: const InputDecoration(labelText: 'Role'),
                      );
                    }),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, sel), child: const Text('Assign')),
                    ],
                  );
                },
              );
              if (roleId != null) context.read<UsersBloc>().add(AssignRoleRequested(u.id, roleId));
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'resend', child: Text('Resend Reset Link')),
            PopupMenuItem(value: 'assign', child: Text('Assign Role')),
            PopupMenuItem(value: 'delete', child: Text('Delete User')),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(PermissionModel p) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: p.description != null ? Text(p.description!) : null,
        trailing: IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: 'Copy permission name',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: p.name));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission name copied')));
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.group_off_outlined, size: 72, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
          const SizedBox(height: 12),
          const Text('No users found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('There are no users to display. Tap the Create User button to add the first user.'),
        ]),
      ),
    );
  }

  Widget _buildEmptyPermissions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_open_outlined, size: 72, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
          const SizedBox(height: 12),
          const Text('No permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('No permissions created yet. Tap Create Permission to add one.'),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<UsersBloc>().add(LoadUsers());
              context.read<UsersBloc>().add(LoadRolesAndPermissions());
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name, username or email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _filtered = List<UserModel>.from(_lastUsers);
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) {
                      setState(() => _isSearching = v.isNotEmpty);
                      _applySearch(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Role'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateUserSheet(_lastRoles),
                  icon: const Icon(Icons.person_add),
                  label: const Text('User'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showCreatePermissionSheet,
                  icon: const Icon(Icons.shield_rounded),
                  label: const Text('Permission'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                ),
              ]),
              const SizedBox(height: 8),
              // View toggle
              Row(children: [
                ChoiceChip(
                  label: const Text('Users'),
                  selected: _viewIndex == 0,
                  onSelected: (_) => setState(() => _viewIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Permissions'),
                  selected: _viewIndex == 1,
                  onSelected: (_) => setState(() => _viewIndex = 1),
                ),
              ]),
            ]),
          ),
        ),
      ),
      body: BlocConsumer<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UsersActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Operation completed successfully')),
            );
          } else if (state is UsersFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to complete operation. Please try again.')),
            );
          } else if (state is RolesPermissionsLoaded) {
            _lastRoles = state.roles;
            _lastPermissions = state.permissions;
          } else if (state is UsersLoaded) {
            _lastUsers = state.users;
            _filtered = List<UserModel>.from(state.users);
          }
        },
        builder: (context, state) {
          if (state is UsersLoading || state is UsersInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewIndex == 1) {
            // Permissions view
            final perms = _lastPermissions;
            if (perms.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<UsersBloc>().add(LoadRolesAndPermissions());
                },
                child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                  const SizedBox(height: 48),
                  _buildEmptyPermissions(),
                ]),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<UsersBloc>().add(LoadRolesAndPermissions());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: perms.length,
                itemBuilder: (ctx, idx) => _buildPermissionTile(perms[idx]),
              ),
            );
          }

          // Users view (mobile-first single column)
          final users = _filtered;
          final roles = _lastRoles;

          if (users.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<UsersBloc>().add(LoadUsers());
                context.read<UsersBloc>().add(LoadRolesAndPermissions());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 48),
                  _buildEmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<UsersBloc>().add(LoadUsers());
              context.read<UsersBloc>().add(LoadRolesAndPermissions());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildUserCard(user, roles);
              },
            ),
          );
        },
      ),
    );
  }
}