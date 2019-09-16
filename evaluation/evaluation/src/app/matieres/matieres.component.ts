import { Component, OnInit } from '@angular/core';
import { Matiere } from '../matiere';
import { MatiereService } from '../matiere.service';

@Component({
  selector: 'app-matieres',
  templateUrl: './matieres.component.html',
  styleUrls: ['./matieres.component.css']
})

export class MatieresComponent implements OnInit {

  matieres: Matiere[];

  constructor(private matiereService: MatiereService) { }

  ngOnInit() {
    this.getMatieres();
  }

  getMatieres(): void {
    this.matiereService.getMatieres()
      .subscribe(matieres => this.matieres = matieres);
  }

}
