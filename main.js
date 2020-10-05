const btnSearch = document.getElementById('btnSearch');
const txtSearch = document.getElementById('myInput');

const reposDiv  = document.getElementById("repos");    
const avatarDiv = document.getElementById("avatar");
const nameDiv   = document.getElementById("personal");
const htmlDiv   = document.getElementById("html_url");

const clearDivs = [reposDiv, avatarDiv, nameDiv, htmlDiv];

let public_repos='';

async function clearAll() {

  for (div in clearDivs) {
    clearDivs[div].innerHTML='';
  }
  } 

async function fetchGithubRepos(initials) {
    const url = `https://api.github.com/users/${initials}/repos`
    const response = await fetch(url);
    const data = await response.json();

    let repos='';
    repos += `${public_repos} public repositories `;
    repos += '<ul>';
    for (repo in data) { 
     let url = 'https://github.com/' + initials + '/'+ data[repo].name;
     let anchor = data[repo].created_at.replace('T',' ').replace('Z',' ') + ' | ' + data[repo].updated_at.replace('T',' ').replace('Z',' ')+ ' | <a href="' + url + '" target="_blank" >' + data[repo].name + '</a>';
     repos += '<li>' + anchor + '</li>'
    }
    repos += '</ul>';
     document.getElementById("repos").innerHTML = repos;    
}

function buildPersonnel (data) {
  let out = '';

  public_repos = data.public_repos;
  const company = data.company || '';
  const bio     = data.bio  || '';
  const created_at     = data.created_at  || '';
  const updated_at     = data.updated_at  || '';


  out +=  `${data.name}  <br />`;
   out +=  `${company}  <br />`;
   out +=  `${bio}  <br />`;
   out +=  `<a href="${data.blog}" target="_blank">${data.blog}</a><br /><br />`;
   out +=  `Created ${created_at.replace('T',' ').replace('Z',' ')}  <br />`;
   out +=  `Updated ${updated_at.replace('T',' ').replace('Z',' ')}  <br />`;
   
  document.getElementById("personal").innerHTML = out;
}

async function fetchGithub(initials) {
    const url = `https://api.github.com/users/${initials}`
    const response = await fetch(url)
  .then(response => {
    if (response.ok) {
      return response.json()
    } else if(response.status === 404) {
      return Promise.reject('github login not found')
    } else {
      return Promise.reject('some other error: ' + response.status)
    }
  })
  .then(data => {
     const url = data.avatar_url; 
     const img = `<img src="${url}" width="200"/>`;
     document.getElementById("avatar").innerHTML = img;
//     document.getElementById("name").innerHTML = data.name;
     buildPersonnel(data);  
     let html_url = `<a href="${data.html_url}" target="_blank">github page</a>`;
     document.getElementById("html_url").innerHTML = html_url;

     fetchGithubRepos(initials);
  })
  .catch(error => {document.getElementById('error').innerHTML= error; 
clearAll();
});
}


btnSearch.onclick = function() {
    let initials=txtSearch.value;
    fetchGithub(initials);

}    
//    let initials='ss'

//fetchGithub(initials);


