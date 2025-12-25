// In the ProfileScreen build method, update the logout button:

// Logout Button
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    key: const Key('logout_button'),
    onPressed: () {
      _confirmLogout();
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      minimumSize: const Size(double.infinity, 50),
    ),
    child: Text(
      "Logout",
      style: text.copyWith(fontSize: 20),
    ),
  ),
),

// Add this method to _ProfileScreenState:
void _confirmLogout() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Logout', style: title),
      content: Text('Are you sure you want to logout?', style: text),
      backgroundColor: Colors.black,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: text.copyWith(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            _logout(); // Perform logout
          },
          child: Text('Logout', style: text.copyWith(color: Colors.red)),
        ),
      ],
    ),
  );
}

// Update the existing _logout method to clear API token:
void _logout() async {
  // Clear API token
  ApiService.clearAuthToken();
  
  // Clear all user data from provider
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
  
  userProvider.logout();
  recipeProvider.logout();
  
  // Navigate to login (clear navigation stack)
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }
}
