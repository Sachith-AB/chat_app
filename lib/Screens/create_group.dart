import 'package:chatapp/CustomUI/avatar_card.dart';
import 'package:chatapp/CustomUI/contact_card.dart';
import 'package:chatapp/Model/chat_model.dart';
import 'package:chatapp/Services/chat_service.dart';
import 'package:chatapp/Screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key, this.sourceChat});

  final ChatModel? sourceChat;

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  List<ChatModel> contacts = [];
  List<ChatModel> groups = [];
  List<Map<String, dynamic>> allUsers = [];
  bool isLoading = true;
  TextEditingController groupNameController = TextEditingController();
  String? groupIconPath;
  ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void loadUsers() async {
    try {
      final users = await ChatService.getUsers();
      setState(() {
        allUsers = users;
        // Convert users to ChatModel for compatibility, excluding current user
        contacts = users
            .where((user) => user['id'] != widget.sourceChat?.id)
            .map(
              (user) => ChatModel(
                id: user['id'],
                name: user['name'],
                status: user['phone'],
                icon: user['avatar'],
              ),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void createGroup() async {
    if (groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one participant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating group...'),
          ],
        ),
      ),
    );

    try {
      List<int> participantIds = groups.map((contact) => contact.id!).toList();
      // Add the current user as well
      participantIds.add(widget.sourceChat!.id!);

      final result = await ChatService.createGroup(
        name: groupNameController.text.trim(),
        createdBy: widget.sourceChat!.id!,
        participants: participantIds,
      );

      Navigator.pop(context); // Close loading dialog

      if (result != null && result['success'] == true) {
        // Upload group icon if selected
        if (groupIconPath != null && result['groupId'] != null) {
          try {
            await ChatService.uploadGroupIcon(
              result['groupId'],
              groupIconPath!,
            );
            print('✅ Group icon uploaded successfully');
          } catch (e) {
            print('⚠️ Error uploading group icon: $e');
            // Don't fail the entire process if icon upload fails
          }
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Group "${groupNameController.text}" created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home and refresh chats
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              sourceChat: widget.sourceChat,
              chatmodels: [], // Will be loaded fresh
            ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Group Icon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              if (groupIconPath != null)
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Remove Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      groupIconPath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          groupIconPath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          groupIconPath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Group',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Add participants',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xff075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality here
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Group name input section
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement image picker for group icon
                              _showImagePickerDialog();
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[300],
                                  child: groupIconPath != null
                                      ? ClipOval(
                                          child: Image.file(
                                            File(groupIconPath!),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(
                                          Icons.group,
                                          color: Colors.grey[600],
                                          size: 30,
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xff075E54),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: groupNameController,
                              decoration: InputDecoration(
                                hintText: 'Group name',
                                border: UnderlineInputBorder(),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xff075E54),
                                  ),
                                ),
                              ),
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey[300]),

                    // Selected participants section
                    if (groups.length > 0)
                      Container(
                        height: 90,
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Participants: ${groups.length}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        // Find the contact in the main list and unselect it
                                        final contactIndex = contacts
                                            .indexWhere(
                                              (contact) =>
                                                  contact.id ==
                                                  groups[index].id,
                                            );
                                        if (contactIndex != -1) {
                                          contacts[contactIndex].select = false;
                                        }
                                        groups.removeAt(index);
                                      });
                                    },
                                    child: AvatarCard(contact: groups[index]),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (groups.length > 0)
                      Divider(height: 1, thickness: 1, color: Colors.grey[300]),

                    // Contacts list
                    Expanded(
                      child: ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          return ContactCard(
                            contact: contacts[index],
                            onTap: () {
                              setState(() {
                                contacts[index].select =
                                    !contacts[index].select;
                                if (contacts[index].select) {
                                  groups.add(contacts[index]);
                                } else {
                                  groups.removeWhere(
                                    (g) => g.id == contacts[index].id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: groups.isNotEmpty
          ? FloatingActionButton(
              onPressed: createGroup,
              backgroundColor: Color(0xff075E54),
              child: Icon(Icons.check, color: Colors.white),
            )
          : null,
    );
  }
}
