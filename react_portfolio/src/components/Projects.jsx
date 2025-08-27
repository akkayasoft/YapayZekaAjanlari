const projects = [
  { title: 'Project One', description: 'Description of project one.' },
  { title: 'Project Two', description: 'Description of project two.' },
];

function Projects() {
  return (
    <section id="projects" className="projects">
      <h2>Projects</h2>
      <ul>
        {projects.map((project) => (
          <li key={project.title}>
            <h3>{project.title}</h3>
            <p>{project.description}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default Projects;
