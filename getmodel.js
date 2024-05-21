// // Function to fetch the model file from the server
// function fetchModel() {
//     const url = 'http://localhost:5000/model/example_mesh_0.obj'; // URL of the model

//     fetch(url)
//         .then(response => {
//             if (!response.ok) {
//                 throw new Error('Network response was not ok ' + response.statusText);
//             }
//             return response.blob(); // Or response.blob() if you want the raw file data
//         })
//         .then(data => {
//             console.log('Model data:', data);
//         })
//         .catch(error => {
//             console.error('There was a problem with the fetch operation:', error);
//         });
// }

// // Call the function to fetch the model
// fetchModel();