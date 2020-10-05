// const btnSearch = document.getElementById('btnSearch');
// const txtSearch = document.getElementById('myInput');


// async function githubAvatar (avatar_url) {
//     const img = '<img src="' + avatar_url + '">'
//     document.getElementById("avatar").innerHTML = img;
// }

// async function fetchGithubRepos(initials) {
//     const url = `https://api.github.com/users/${initials}/repos`
//     const response = await fetch(url);
//     const data = await response.json();
//     return data;
// }


// btnSearch.onclick = function() {

// let initials=txtSearch.value;

// fetchGithub(initials).then(data => {
//  });

// fetchGithubRepos(initials).then(data => {
//     let repos='<ul>';
//     for (repo in data) { 
//      repos += '<li>' +data[repo].name+ '</li>'
//     }
//     repos += '</ul>';
//      document.getElementById("repos").innerHTML = repos;    
// });

// }


// async function makeRequest(initials) {
//     const response = await fetch(`https://api.github.com/users/${initials}`);


// async function fetchGithub(initials) {
//     try {
//     const response = await fetch(`https://api.github.com/users/${initials}`);
//     const data     = await response.json();
//     const avatar   = await githubAvatar(data.avatar_url)
//     } catch(err) {
//         console.log(err);
//     }

//   }

//   let initials = 'frimannss';

//   fetchGithub(initials);


function handleErrors(response) {
    if (!response.ok) {
        throw Error(response.statusText);
    }
    return response;
}

// fetch("http://httpstat.us/500")
//     .then(handleErrors)
//     .then(response => console.log("ok") )
//     .catch(error => console.log(error) );




  async function getUserAsync(name) 
  {
    let response = await fetch(`https://api.github.com/users/${name}`)
    console.log(response.ok)
    if (response.ok === 'false' ) throw 'not found';

    let data = await response.json();
    return data;
  }

  async function doWork (initials) {
      try {
      const stamData = await getUserAsync(initials)
      console.log('stamData.avatar_url')  
    } catch (err) {
        console.log(err)
    }
  }
let initials ='frimannss'


function getUser(username) {
    return fetch(`https://api.github.com/users/${username}`)
    .then(response => response.json())
    .then(response => {
    //    console.log(response);
    //    return response;
    })
}

const abc = getUser('frimanns');


//doWork(initials)
