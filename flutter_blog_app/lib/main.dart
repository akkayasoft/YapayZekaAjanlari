import 'package:flutter/material.dart';

void main() {
  runApp(const BlogApp());
}

class BlogApp extends StatelessWidget {
  const BlogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PostListPage(),
    );
  }
}

class Post {
  final String title;
  final String body;

  Post({required this.title, required this.body});
}

final List<Post> demoPosts = [
  Post(title: 'Hello World', body: 'Welcome to my blog!'),
  Post(title: 'Second Post', body: 'More content here.'),
  Post(title: 'Flutter Tips', body: 'Using Flutter for building apps.'),
];

class PostListPage extends StatelessWidget {
  const PostListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Posts')),
      body: ListView.builder(
        itemCount: demoPosts.length,
        itemBuilder: (context, index) {
          final post = demoPosts[index];
          return ListTile(
            title: Text(post.title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(post: post),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(post.body),
      ),
    );
  }
}
