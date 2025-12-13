void _logout() async {
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.black,
      title: Text('Logout', style: title.copyWith(fontSize: 24)),
      content: Text('Are you sure you want to logout?', style: text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: footerClickable),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            
            // 1. Clear all user data from provider
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            await userProvider.logout();
            
            // 2. Navigate to login (clear navigation stack)
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Remove all previous routes
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Logout', style: text),
        ),
      ],
    ),
  );
}
