if (location.protocol !== 'https:') {
    location.replace(`https:${location.href.substring(location.protocol.length)}`);
}

// Load deployment time from file
async function loadDeploymentTime() {
    try {
        const response = await fetch('/js/deployment-info.json');
        const data = await response.json();
        
        if (data.last_deployed) {
            // Format the date nicely
            const date = new Date(data.timestamp * 1000);
            document.getElementById('last-updated').textContent = data.last_deployed;
        } else {
            document.getElementById('last-updated').textContent = 'Unknown';
        }
    } catch (error) {
        console.log('Deployment info not available, using current time');
        document.getElementById('last-updated').textContent = new Date().toLocaleString();
    }
}

// Call the function when page loads
loadDeploymentTime();

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add scroll effect to header
window.addEventListener('scroll', function() {
    const header = document.querySelector('header');
    if (window.scrollY > 100) {
        header.style.background = 'rgba(255, 255, 255, 0.98)';
        header.style.backdropFilter = 'blur(10px)';
    } else {
        header.style.background = 'rgba(255, 255, 255, 0.95)';
        header.style.backdropFilter = 'none';
    }
});
